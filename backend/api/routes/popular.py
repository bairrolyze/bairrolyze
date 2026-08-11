"""Region-scoped 'popular areas' endpoint.

Reads back the aggregated most-searched areas within a region (counted by the
analyze pipeline in `services/popularity_store.py`). The mobile app blends this
with its curated fallback list, so an empty/sparse result here is normal and
expected for cold-start regions — the client fills the gap.
"""

import logging

from fastapi import APIRouter, Query

from models.schemas import PopularAreaStat, PopularAreasResponse
from services.popularity_store import popularity_store

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/popular", response_model=PopularAreasResponse)
async def get_popular_areas(
    region: str = Query(..., min_length=1, description="Region/city to scope to, e.g. 'Lisboa'"),
    country: str = Query("PT", max_length=3, description="ISO country code"),
    limit: int = Query(8, ge=1, le=25),
):
    """Most-searched areas within `region`, most popular first.

    Returns an empty `areas` list (not an error) when there is no data yet for
    the region — the client falls back to its curated set.
    """
    rows = await popularity_store.top_areas(country, region, limit)
    return PopularAreasResponse(
        country=country.upper(),
        region=region,
        areas=[PopularAreaStat(name=name, count=count) for name, count in rows],
    )
