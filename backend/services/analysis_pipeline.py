"""Background orchestration for the 4-stage analyze pipeline.

geocode -> amenities -> score -> ai_summary

This is a STRICT sequential dependency chain (amenities needs geocode's
lat/lng, score needs amenities, ai_summary needs score+amenities) so stages
run one after another, not concurrently — the value of this module is
progressive result delivery (each stage's result is persisted to the job
store as soon as it's ready, so /status and /stream can surface it
immediately), not stage-level parallelism.

`nominatim_service.geocode()`, `overpass_service.fetch_amenities()`, and
`calculate_location_score()` are called here as black boxes with their
existing signatures — their internals are not touched by this module, so a
parallel effort rewriting them (Redis caching / bbox Overpass rewrite) can
land underneath this pipeline without conflict.
"""

import logging
import time
from datetime import datetime
from typing import Optional

from ai.summary_generator import summary_generator
from config.settings import settings
from geocoding.nominatim import nominatim_service
from models.schemas import AnalyzeRequest, AnalyzeResponse
from scoring.scoring_engine import calculate_location_score
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
from services.overpass_service import overpass_service

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

        geo = await _run_geocode_stage(analysis_id, request)
        amenities = None
        score = None
        ai_summary = None
        failed_stage: Optional[str] = None

        if geo is None:
            failed_stage = "geocode"
        else:
            amenities = await _run_amenities_stage(analysis_id, request, geo)
            if amenities is None:
                failed_stage = "amenities"

        if failed_stage is None:
            score = await _run_score_stage(analysis_id, request, amenities)
            if score is None:
                failed_stage = "score"
        else:
            await job_store.update_stage(analysis_id, "score", STAGE_BLOCKED, error=f"blocked_by:{failed_stage}")

        if failed_stage is None:
            ai_summary = await _run_ai_summary_stage(analysis_id, request, score, amenities)
            # ai_summary always resolves to STAGE_DONE (it has its own
            # fallback path), so it never sets failed_stage.
        else:
            await job_store.update_stage(analysis_id, "ai_summary", STAGE_BLOCKED, error=f"blocked_by:{failed_stage}")

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


async def _run_geocode_stage(analysis_id: str, request: AnalyzeRequest):
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "geocode", STAGE_RUNNING)
    try:
        geo = await nominatim_service.geocode(request.address, request.country_code)
    except ValueError as e:
        # Same semantics as the original blocking /analyze: address not
        # found is an expected outcome, not a crash.
        await job_store.update_stage(analysis_id, "geocode", STAGE_ERROR, error=f"not_found: {e}")
        logger.warning(
            "analysis_pipeline.stage_failed",
            extra={"analysis_id": analysis_id, "stage": "geocode", "error": str(e), "duration_ms": _ms(stage_start)},
        )
        return None
    except Exception as e:
        await job_store.update_stage(analysis_id, "geocode", STAGE_ERROR, error=f"geocoding_failed: {e}")
        logger.error(
            "analysis_pipeline.stage_failed",
            extra={"analysis_id": analysis_id, "stage": "geocode", "error": str(e), "duration_ms": _ms(stage_start)},
            exc_info=True,
        )
        return None

    await job_store.update_stage(analysis_id, "geocode", STAGE_DONE, result=geo.model_dump(mode="json"))
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "geocode", "duration_ms": _ms(stage_start)},
    )
    return geo


async def _run_amenities_stage(analysis_id: str, request: AnalyzeRequest, geo):
    """Amenities is a soft dependency: if Overpass times out or errors,
    degrade to an empty amenity list (and a correspondingly low score)
    rather than blocking score/ai_summary — same semantics as the original
    blocking /analyze endpoint. A blocked pipeline here is worse for the
    user than a partial/degraded result. Genuine hard failures (geocode not
    resolving) still stop the pipeline via _run_geocode_stage.
    """
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "amenities", STAGE_RUNNING)
    try:
        amenities = await overpass_service.fetch_amenities(lat=geo.lat, lng=geo.lng, radius=request.radius)
    except Exception as e:
        logger.warning(
            "analysis_pipeline.amenities_degraded",
            extra={"analysis_id": analysis_id, "stage": "amenities", "error": str(e), "duration_ms": _ms(stage_start)},
        )
        amenities = []

    await job_store.update_stage(
        analysis_id,
        "amenities",
        STAGE_DONE,
        result=[a.model_dump(mode="json") for a in amenities],
    )
    logger.info(
        "analysis_pipeline.stage_done",
        extra={
            "analysis_id": analysis_id,
            "stage": "amenities",
            "duration_ms": _ms(stage_start),
            "count": len(amenities),
        },
    )
    return amenities


async def _run_score_stage(analysis_id: str, request: AnalyzeRequest, amenities):
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "score", STAGE_RUNNING)
    try:
        score = calculate_location_score(amenities, request.profile)
    except Exception as e:
        await job_store.update_stage(analysis_id, "score", STAGE_ERROR, error=f"scoring_failed: {e}")
        logger.error(
            "analysis_pipeline.stage_failed",
            extra={"analysis_id": analysis_id, "stage": "score", "error": str(e), "duration_ms": _ms(stage_start)},
            exc_info=True,
        )
        return None

    await job_store.update_stage(analysis_id, "score", STAGE_DONE, result=score.model_dump(mode="json"))
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "score", "duration_ms": _ms(stage_start)},
    )
    return score


async def _run_ai_summary_stage(analysis_id: str, request: AnalyzeRequest, score, amenities) -> str:
    """AI summary is optional and always resolves to STAGE_DONE — same
    fallback semantics as the original blocking /analyze endpoint: no API
    key, or a generation error, both fall back to a deterministic summary
    rather than failing the stage.
    """
    stage_start = time.monotonic()
    await job_store.update_stage(analysis_id, "ai_summary", STAGE_RUNNING)

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

    await job_store.update_stage(analysis_id, "ai_summary", STAGE_DONE, result=ai_summary)
    logger.info(
        "analysis_pipeline.stage_done",
        extra={"analysis_id": analysis_id, "stage": "ai_summary", "duration_ms": _ms(stage_start)},
    )
    return ai_summary
