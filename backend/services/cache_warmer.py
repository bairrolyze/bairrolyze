"""Pre-warms the amenities cache for popular areas.

Overpass is shared, capacity-limited public infrastructure (see
services/overpass_service.py) that fails outright under load. Most real
user traffic concentrates on a small set of popular areas (tracked by
services/popularity_store.py from real searches) — warming those ahead of
time means that traffic hits the 7-day amenities cache instead of a live,
failure-prone Overpass call, independent of whether Overpass happens to be
up at the moment a user searches.

This only warms areas popularity_store already has real search data for —
there is nothing to warm for a brand new deployment until real traffic
accumulates.
"""

import logging
from typing import Dict, List

from geocoding.nominatim import nominatim_service
from services.overpass_service import overpass_service
from services.popularity_store import popularity_store

logger = logging.getLogger(__name__)

DEFAULT_WARM_RADIUS = 2000.0


async def warm_area(country_code: str, region: str, area: str, radius: float = DEFAULT_WARM_RADIUS) -> bool:
    """Geocode one area, then fetch (and thereby cache) its amenities.

    fetch_amenities caches its own result on success, so this function's
    only job is to trigger that cache write for a specific area; it returns
    whether the warm succeeded so the caller can report it.
    """
    try:
        geo = await nominatim_service.geocode(f"{area}, {region}", country_code)
    except Exception as exc:  # noqa: BLE001 - warming is best-effort
        logger.warning(
            "cache_warmer.geocode_failed",
            extra={"area": area, "region": region, "country": country_code, "error": str(exc)},
        )
        return False

    try:
        await overpass_service.fetch_amenities(lat=geo.lat, lng=geo.lng, radius=radius)
    except Exception as exc:  # noqa: BLE001 - warming is best-effort
        logger.warning(
            "cache_warmer.amenities_failed",
            extra={"area": area, "region": region, "country": country_code, "error": str(exc)},
        )
        return False

    return True


async def warm_popular_areas(limit_per_region: int = 10) -> Dict[str, List[str]]:
    """Warm the amenities cache for every tracked region's top searched
    areas, one request at a time — Overpass capacity is the bottleneck here,
    not something to parallelize against.
    """
    warmed: List[str] = []
    failed: List[str] = []

    for country_code, region in await popularity_store.list_tracked_regions():
        top = await popularity_store.top_areas(country_code, region, limit=limit_per_region)
        for area, _count in top:
            label = f"{area}, {region} ({country_code})"
            ok = await warm_area(country_code, region, area)
            (warmed if ok else failed).append(label)

    logger.info("cache_warmer.warm_popular_areas_done", extra={"warmed": len(warmed), "failed": len(failed)})
    return {"warmed": warmed, "failed": failed}
