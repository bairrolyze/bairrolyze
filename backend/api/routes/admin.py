"""Admin-only maintenance endpoints, gated by the X-API-Key header against
settings.admin_api_key (same auth pattern as the dormant leads.py admin
routes this mirrors).
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException

from config.settings import settings
from services.cache_warmer import warm_popular_areas

logger = logging.getLogger(__name__)
router = APIRouter()


async def verify_admin_api_key(x_api_key: Optional[str] = Header(None)):
    if not settings.admin_api_key:
        raise HTTPException(status_code=500, detail="Admin API key not configured on server")
    if not x_api_key or x_api_key != settings.admin_api_key:
        raise HTTPException(status_code=403, detail="Invalid or missing X-API-Key header")
    return True


@router.post("/admin/warm-cache", dependencies=[Depends(verify_admin_api_key)])
async def warm_cache(limit_per_region: int = 10):
    """Pre-fetch and cache amenities for every region's top searched areas,
    so real user traffic mostly hits the amenities cache instead of a live
    (capacity-limited, failure-prone) Overpass call.
    """
    result = await warm_popular_areas(limit_per_region=limit_per_region)
    logger.info(
        "admin.warm_cache",
        extra={"warmed": len(result["warmed"]), "failed": len(result["failed"])},
    )
    return result
