"""Background orchestration for the 5-stage analyze pipeline.

address_found -> map_ready -> amenities_ready -> score_ready -> summary_ready

address_found and map_ready both come from the single geocode() call, split
into two stages purely for UI granularity (so the client can render the
address text before the map is ready to zoom) — not two network round-trips.

This is a STRICT sequential dependency chain (amenities needs geocode's
lat/lng, score needs amenities, summary needs score+amenities) so stages run
one after another, not concurrently — the value of this module is
progressive result delivery (each stage's result is persisted to the job
store as soon as it's ready, so /status and /stream can surface it
immediately), not stage-level parallelism.

`nominatim_service.geocode()`, `overpass_service.fetch_amenities()`, and
`calculate_location_score()` are called here as black boxes with their
existing signatures — their internals are not touched by this module.

DNA and Timeline stay client-side (Flutter derives them from the score
already in this payload) — deliberately not backend stages here. Neither has
a real server-side data source today (DNA is a pure rendering of the
category scores already present; Timeline is explicitly synthetic client
data), so adding dna_ready/timeline_ready events would just relabel existing
data with no new information, or worse, imply a real computation that
doesn't exist.
"""

import logging
import time
from datetime import datetime
from typing import Optional

from ai.summary_generator import summary_generator
from config.settings import settings
from geocoding.nominatim import nominatim_service
from models.schemas import AnalyzeRequest, AnalyzeResponse, CrimeReport
from scoring.scoring_engine import calculate_location_score
from services.crime_service import crime_service
from services.job_store import (
    STAGE_BLOCKED,
    STAGE_DONE,
    STAGE_ERROR,
    STAGE_RUNNING,
    STATUS_DONE,
    STATUS_ERROR,
    STATUS_RUNNING,
    job_store,
)
from services.overpass_service import _compute_bbox, overpass_service
from services.popularity_store import popularity_store

logger = logging.getLogger(__name__)


def _ms(start: float) -> int:
    return int((time.monotonic() - start) * 1000)


async def run_analysis_pipeline(analysis_id: str, request: AnalyzeRequest) -> None:
    """Runs as a FastAPI BackgroundTask after POST /analyze returns 202.

    A failure in any stage is recorded on that stage (not raised), the
    remaining downstream stages are marked 'blocked', and the job is still
    resolved to status 'done' with partial_failure=True — never left stuck
    'running'. Only a genuinely unexpected bug in this orchestration itself
    (not a stage failure) results in job status 'error'.
    """
    pipeline_start = time.monotonic()
    logger.info(
        "analysis_pipeline.start",
        extra={"analysis_id": analysis_id, "address": request.address, "profile": request.profile},
    )

    try:
        await job_store.set_job_status(analysis_id, STATUS_RUNNING)

        geo = await _run_geocode_stages(analysis_id, request)
        amenities = None
        crime = None
        score = None
        ai_summary = None
        failed_stage: Optional[str] = None

        if geo is None:
            failed_stage = "map_ready"
            await job_store.update_stage(analysis_id, "crime_ready", STAGE_BLOCKED, error="blocked_by:address_found")
        else:
            amenities = await _run_amenities_stage(analysis_id, request, geo)
            if amenities is None:
                failed_stage = "amenities_ready"
            # Crime is a soft, independent stage (needs only geo + country) —
            # it always resolves DONE and never blocks scoring.
            crime = await _run_crime_stage(analysis_id, request, geo)

        if failed_stage is None:
            score = await _run_score_stage(analysis_id, request, amenities)
            if score is None:
                failed_stage = "score_ready"
        else:
            await job_store.update_stage(analysis_id, "score_ready", STAGE_BLOCKED, error=f"blocked_by:{failed_stage}")

        if failed_stage is None:
            ai_summary = await _run_ai_summary_stage(analysis_id, request, score, amenities)
            # summary_ready always resolves to STAGE_DONE (it has its own
            # fallback path), so it never sets failed_stage.
        else:
            await job_store.update_stage(analysis_id, "summary_ready", STAGE_BLOCKED, error=f"blocked_by:{failed_stage}")

        partial_failure = failed_stage is not None
        final_payload = None
        if not partial_failure:
            final_payload = AnalyzeResponse(
                id=analysis_id,
                analyzed_at=datetime.utcnow(),
                address=geo,
                score=score,
                amenities=amenities,
                ai_summary=ai_summary,
                profile=request.profile,
                crime=crime,
            ).model_dump(mode="json")

        await job_store.set_job_status(
            analysis_id,
            STATUS_DONE,
            partial_failure=partial_failure,
            final=final_payload,
        )

        if partial_failure:
            logger.warning(
                "analysis_pipeline.partial_failure",
                extra={
                    "analysis_id": analysis_id,
                    "failed_stage": failed_stage,
                    "duration_ms": _ms(pipeline_start),
                },
            )
        else:
            logger.info(
                "analysis_pipeline.complete",
                extra={"analysis_id": analysis_id, "duration_ms": _ms(pipeline_start)},
            )

    except Exception as exc:  # noqa: BLE001 - safety net so the job never hangs "running"
        logger.error(
            "analysis_pipeline.crashed",
            extra={"analysis_id": analysis_id, "duration_ms": _ms(pipeline_start)},
            exc_info=True,
        )
        await job_store.set_job_status(analysis_id, STATUS_ERROR, partial_failure=True)


async def _run_geocode_stages(analysis_id: str, request: AnalyzeRequest):
    """Runs the single geocode() call, then emits it as two stages:
    address_found (address text/country/city — as soon as we know *where*)
    followed immediately by map_ready (lat/lng + bounding box — what the map
    needs to zoom). One network call, two progressive UI moments.
    """
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "address_found", STAGE_RUNNING)
    try:
        geo = await nominatim_service.geocode(request.address, request.country_code)
    except ValueError as e:
        # Same semantics as the original blocking /analyze: address not
        # found is an expected outcome, not a crash.
        error = f"not_found: {e}"
        await job_store.update_stage(analysis_id, "address_found", STAGE_ERROR, error=error)
        await job_store.update_stage(analysis_id, "map_ready", STAGE_BLOCKED, error="blocked_by:address_found")
        logger.warning(
            "analysis_pipeline.stage_failed",
            extra={"analysis_id": analysis_id, "stage": "address_found", "error": str(e), "duration_ms": _ms(stage_start)},
        )
        return None
    except Exception as e:
        error = f"geocoding_failed: {e}"
        await job_store.update_stage(analysis_id, "address_found", STAGE_ERROR, error=error)
        await job_store.update_stage(analysis_id, "map_ready", STAGE_BLOCKED, error="blocked_by:address_found")
        logger.error(
            "analysis_pipeline.stage_failed",
            extra={"analysis_id": analysis_id, "stage": "address_found", "error": str(e), "duration_ms": _ms(stage_start)},
            exc_info=True,
        )
        return None

    geo_json = geo.model_dump(mode="json")
    await job_store.update_stage(analysis_id, "address_found", STAGE_DONE, result=geo_json)
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "address_found", "duration_ms": _ms(stage_start)},
    )

    # Record this search for region-scoped "popular areas" (best-effort; never
    # blocks or fails the pipeline). Uses the authoritative request country and
    # the geocoded region (city) + area (suburb/neighbourhood).
    await popularity_store.record_search(
        country_code=request.country_code,
        region=geo.city,
        area=geo.district,
    )

    map_start = time.monotonic()
    await job_store.update_stage(analysis_id, "map_ready", STAGE_RUNNING)
    south, west, north, east = _compute_bbox(geo.lat, geo.lng, request.radius)
    map_result = {
        "lat": geo.lat,
        "lng": geo.lng,
        "display_name": geo.display_name,
        "bbox": {"south": south, "west": west, "north": north, "east": east},
    }
    await job_store.update_stage(analysis_id, "map_ready", STAGE_DONE, result=map_result)
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "map_ready", "duration_ms": _ms(map_start)},
    )
    return geo


async def _run_amenities_stage(analysis_id: str, request: AnalyzeRequest, geo):
    """Amenities is a soft dependency: if Overpass times out or errors,
    degrade to an empty amenity list (and a correspondingly low score)
    rather than blocking score/summary — same semantics as the original
    blocking /analyze endpoint. A blocked pipeline here is worse for the
    user than a partial/degraded result. Genuine hard failures (geocode not
    resolving) still stop the pipeline via _run_geocode_stages.
    """
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "amenities_ready", STAGE_RUNNING)
    try:
        amenities = await overpass_service.fetch_amenities(lat=geo.lat, lng=geo.lng, radius=request.radius)
    except Exception as e:
        logger.warning(
            "analysis_pipeline.amenities_degraded",
            extra={"analysis_id": analysis_id, "stage": "amenities_ready", "error": str(e), "duration_ms": _ms(stage_start)},
        )
        amenities = []

    await job_store.update_stage(
        analysis_id,
        "amenities_ready",
        STAGE_DONE,
        result=[a.model_dump(mode="json") for a in amenities],
    )
    logger.info(
        "analysis_pipeline.stage_done",
        extra={
            "analysis_id": analysis_id,
            "stage": "amenities_ready",
            "duration_ms": _ms(stage_start),
            "count": len(amenities),
        },
    )
    return amenities


async def _run_crime_stage(analysis_id: str, request: AnalyzeRequest, geo) -> CrimeReport:
    """Real crime data for UK (GB) addresses via the UK Police API; elsewhere
    there is no open point-level crime API, so this resolves to an
    'unavailable' report and safety stays on the OSM-based proxy. Soft stage:
    a fetch failure degrades to 'unavailable' and never blocks scoring.
    """
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "crime_ready", STAGE_RUNNING)
    try:
        if (request.country_code or "").upper() == "GB":
            report = await crime_service.fetch_uk_crime(geo.lat, geo.lng)
        else:
            report = CrimeReport(
                source="osm",
                available=False,
                note="No open crime API for this region; safety is based on nearby "
                "emergency services (OpenStreetMap).",
            )
    except Exception as e:  # noqa: BLE001 - soft stage, degrade rather than block
        logger.warning(
            "analysis_pipeline.crime_degraded",
            extra={"analysis_id": analysis_id, "error": str(e), "duration_ms": _ms(stage_start)},
        )
        report = CrimeReport(
            source="unavailable",
            available=False,
            note="Crime data temporarily unavailable.",
        )

    await job_store.update_stage(
        analysis_id, "crime_ready", STAGE_DONE, result=report.model_dump(mode="json")
    )
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "crime_ready", "duration_ms": _ms(stage_start)},
    )
    return report


async def _run_score_stage(analysis_id: str, request: AnalyzeRequest, amenities):
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "score_ready", STAGE_RUNNING)
    try:
        score = calculate_location_score(amenities, request.profile)
    except Exception as e:
        await job_store.update_stage(analysis_id, "score_ready", STAGE_ERROR, error=f"scoring_failed: {e}")
        logger.error(
            "analysis_pipeline.stage_failed",
            extra={"analysis_id": analysis_id, "stage": "score_ready", "error": str(e), "duration_ms": _ms(stage_start)},
            exc_info=True,
        )
        return None

    await job_store.update_stage(analysis_id, "score_ready", STAGE_DONE, result=score.model_dump(mode="json"))
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "score_ready", "duration_ms": _ms(stage_start)},
    )
    return score


async def _run_ai_summary_stage(analysis_id: str, request: AnalyzeRequest, score, amenities) -> str:
    """AI summary is optional and always resolves to STAGE_DONE — same
    fallback semantics as the original blocking /analyze endpoint: no API
    key, or a generation error, both fall back to a deterministic summary
    rather than failing the stage. This MUST NOT block earlier stages —
    it's the last stage in the chain, so it never can.
    """
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "summary_ready", STAGE_RUNNING)

    if settings.openai_api_key:
        try:
            ai_summary = await summary_generator.generate(address=request.address, score=score, amenities=amenities)
        except Exception as e:
            logger.warning(
                "analysis_pipeline.ai_summary_fallback",
                extra={"analysis_id": analysis_id, "error": str(e), "duration_ms": _ms(stage_start)},
            )
            ai_summary = summary_generator._fallback_summary(score, request.address)
    else:
        ai_summary = summary_generator._fallback_summary(score, request.address)

    await job_store.update_stage(analysis_id, "summary_ready", STAGE_DONE, result=ai_summary)
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "summary_ready", "duration_ms": _ms(stage_start)},
    )
    return ai_summary
