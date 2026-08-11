"""Country-scoped area/neighbourhood autocomplete for the Explore search box.

Tier 3 of Explore's search (curated + trending are resolved client-side): this
returns any browsable area within the selected country, via Nominatim filtered
to settlement / sub-city results. Selecting one runs a normal analysis.
"""

import logging

from fastapi import APIRouter, Query

from geocoding.nominatim import nominatim_service
from models.schemas import AreaSearchResponse

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/areas/search", response_model=AreaSearchResponse)
async def search_areas(
    q: str = Query(..., min_length=1, description="Partial area name"),
    country: str = Query("PT", max_length=3, description="ISO country code to scope to"),
    limit: int = Query(8, ge=1, le=20),
):
    """Areas matching `q` within `country`, most relevant first.

    Returns an empty list (not an error) when nothing matches or the geocoder
    is unavailable — the client falls back to its curated/trending results.
    """
    try:
        results = await nominatim_service.search_areas(q, country, limit)
    except Exception as exc:  # noqa: BLE001 - degrade to empty rather than 500
        logger.warning("areas.search_failed", extra={"error": str(exc)})
        results = []
    return AreaSearchResponse(country=country.upper(), query=q, results=results)
