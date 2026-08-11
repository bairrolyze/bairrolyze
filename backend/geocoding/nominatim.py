import logging
import time

import httpx
from typing import Optional
from config.settings import settings
from models.schemas import AreaSearchResult, GeocodeResponse
from services.cache import cache_service

logger = logging.getLogger(__name__)

GEOCODE_CACHE_TTL_SECONDS = 2592000  # 30 days
AREA_SEARCH_CACHE_TTL_SECONDS = 86400  # 1 day — autocomplete results

# OSM place types we treat as searchable "areas" (settlements + sub-city
# districts). Everything else (roads, POIs, shops) is filtered out so the box
# only returns places you'd actually browse.
_AREA_PLACE_TYPES = {
    "city", "town", "village", "hamlet",
    "suburb", "neighbourhood", "quarter", "borough", "municipality",
}


def _area_search_cache_key(q: str, country_code: str) -> str:
    return f"areas:{country_code.strip().lower()}:{q.strip().lower()}"


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
            district=(
                addr_details.get("suburb")
                or addr_details.get("neighbourhood")
                or addr_details.get("quarter")
                or addr_details.get("city_district")
                or addr_details.get("borough")
            ),
            confidence=float(result.get("importance", 1.0)),
        )

        await cache_service.set(
            cache_key, geocode_response.model_dump(), GEOCODE_CACHE_TTL_SECONDS
        )

        return geocode_response

    async def search_areas(
        self, q: str, country_code: str = "PT", limit: int = 8
    ) -> list[AreaSearchResult]:
        """Country-scoped area/neighbourhood autocomplete.

        Searches Nominatim restricted to `country_code`, keeping only
        settlement / sub-city results (see `_AREA_PLACE_TYPES` + admin
        boundaries) so the caller gets browsable areas, not streets or shops.
        Cached per (country, query) for a day to stay within Nominatim usage
        limits — clients should still debounce keystrokes.
        """
        q = q.strip()
        if not q:
            return []

        cache_key = _area_search_cache_key(q, country_code)
        cached = await cache_service.get(cache_key)
        if cached is not None:
            return [AreaSearchResult(**r) for r in cached]

        params = {
            "q": q,
            "format": "json",
            "addressdetails": 1,
            "namedetails": 1,
            # Over-fetch, since we filter down to area-like results.
            "limit": min(limit * 3, 30),
            "countrycodes": country_code.lower(),
        }
        response = await self.client.get("/search", params=params)
        response.raise_for_status()
        results = response.json()

        out: list[AreaSearchResult] = []
        seen: set[tuple] = set()
        for r in results:
            cls, typ = r.get("class"), r.get("type")
            is_area = (cls == "place" and typ in _AREA_PLACE_TYPES) or (
                cls == "boundary" and typ == "administrative"
            )
            if not is_area:
                continue
            addr = r.get("address", {})
            names = r.get("namedetails") or {}
            name = (
                names.get("name")
                or r.get("name")
                or r.get("display_name", "").split(",")[0].strip()
            )
            if not name:
                continue
            region = (
                addr.get("city")
                or addr.get("town")
                or addr.get("municipality")
                or addr.get("village")
                or addr.get("county")
                or name
            )
            key = (name.lower(), region.lower())
            if key in seen:
                continue
            seen.add(key)
            out.append(
                AreaSearchResult(
                    name=name,
                    region=region,
                    lat=float(r["lat"]),
                    lng=float(r["lon"]),
                    type=typ or cls or "",
                )
            )
            if len(out) >= limit:
                break

        await cache_service.set(
            cache_key, [o.model_dump() for o in out], AREA_SEARCH_CACHE_TTL_SECONDS
        )
        return out

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
