import logging
import uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException
from models.schemas import AnalyzeRequest, AnalyzeResponse
from geocoding.nominatim import nominatim_service
from services.overpass_service import overpass_service
from scoring.scoring_engine import calculate_location_score
from ai.summary_generator import summary_generator
from config.settings import settings

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_address(request: AnalyzeRequest):
    """
    Full pipeline: geocode → fetch amenities → score → AI summary.
    This is the primary endpoint called by the mobile app.
    """
    # 1. Geocode
    try:
        geo = await nominatim_service.geocode(request.address, request.country_code)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Geocoding failed: {e}")

    # 2. Fetch amenities. This is a soft dependency: if Overpass times out or
    # errors, degrade to an empty amenity list (and a correspondingly low
    # score) rather than failing the whole request — a 502 here is worse for
    # the user than a partial/degraded result. Genuine hard failures (e.g.
    # the address not resolving above) still fail the request.
    try:
        amenities = await overpass_service.fetch_amenities(
            lat=geo.lat, lng=geo.lng, radius=request.radius
        )
    except Exception as e:
        logger.warning(
            f"Amenity fetch failed for address={request.address!r} "
            f"lat={geo.lat} lng={geo.lng} radius={request.radius}: {e}. "
            f"Degrading gracefully with an empty amenity list."
        )
        amenities = []

    # 3. Score
    try:
        score = calculate_location_score(amenities, request.profile)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Scoring failed: {e}")

    # 4. AI Summary (optional)
    ai_summary = None
    if settings.openai_api_key:
        try:
            ai_summary = await summary_generator.generate(
                address=request.address,
                score=score,
                amenities=amenities,
            )
        except Exception:
            ai_summary = summary_generator._fallback_summary(score, request.address)
    else:
        ai_summary = summary_generator._fallback_summary(score, request.address)

    return AnalyzeResponse(
        id=str(uuid.uuid4()),
        analyzed_at=datetime.utcnow(),
        address=geo,
        score=score,
        amenities=amenities,
        ai_summary=ai_summary,
        profile=request.profile,
    )
