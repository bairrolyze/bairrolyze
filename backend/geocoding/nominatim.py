import logging
import time

import httpx
from typing import Optional
from config.settings import settings
from models.schemas import GeocodeResponse
from services.cache import cache_service

logger = logging.getLogger(__name__)

GEOCODE_CACHE_TTL_SECONDS = 2592000  # 30 days


def _geocode_cache_key(address: str, country_code: str) -> str:
    normalized = address.strip().lower()
    return f"geocode:{country_code.strip().lower()}:{normalized}"


class NominatimService:
    def __init__(self):
        self.client = httpx.AsyncClient(
            base_url=settings.nominatim_url,
            headers={"User-Agent": settings.nominatim_user_agent},
            timeout=30.0,
        )

    async def geocode(self, address: str, country_code: str = "PT") -> GeocodeResponse:
        cache_key = _geocode_cache_key(address, country_code)
        cached = await cache_service.get(cache_key)
        if cached is not None:
            logger.info(f"Geocode cache HIT key={cache_key}")
            return GeocodeResponse(**cached)
        logger.info(f"Geocode cache MISS key={cache_key}")

        params = {
            "q": address,
            "format": "json",
            "limit": 1,
            "addressdetails": 1,
            "countrycodes": country_code.lower(),
        }

        start = time.monotonic()
        response = await self.client.get("/search", params=params)
        duration_ms = (time.monotonic() - start) * 1000
        logger.info(f"Nominatim geocode lookup took {duration_ms:.0f}ms address={address!r}")
        response.raise_for_status()
        results = response.json()

        if not results:
            raise ValueError(f"Address not found: {address}")

        result = results[0]
        addr_details = result.get("address", {})

        geocode_response = GeocodeResponse(
            lat=float(result["lat"]),
            lng=float(result["lon"]),
            display_name=result.get("display_name", address),
            country=addr_details.get("country", ""),
            city=(
                addr_details.get("city")
                or addr_details.get("town")
                or addr_details.get("municipality")
                or addr_details.get("village")
            ),
            confidence=float(result.get("importance", 1.0)),
        )

        await cache_service.set(
            cache_key, geocode_response.model_dump(), GEOCODE_CACHE_TTL_SECONDS
        )

        return geocode_response

    async def reverse_geocode(self, lat: float, lng: float) -> Optional[str]:
        params = {"lat": lat, "lon": lng, "format": "json"}
        response = await self.client.get("/reverse", params=params)
        if response.status_code == 200:
            data = response.json()
            return data.get("display_name")
        return None

    async def close(self):
        await self.client.aclose()


nominatim_service = NominatimService()
