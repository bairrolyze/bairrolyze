"""UK crime data via the Police API (data.police.uk).

Free, no API key, street-level (crimes within ~1 mile of a point for a given
month). Only meaningful for UK (GB) addresses — elsewhere there is no open
point-level crime API, so callers fall back to the OSM-based safety proxy.

Follows the same async-httpx-client-closed-in-lifespan pattern as the other
external service clients (nominatim/overpass) — the client is created here and
closed from main.py's lifespan shutdown hook.
"""

import logging
from typing import Optional

import httpx

from config.settings import settings
from models.schemas import CrimeReport

logger = logging.getLogger(__name__)

# The UK Police API returns street-level crimes within roughly a 1-mile
# radius of the requested point.
_POLICE_API_RADIUS_M = 1609


class CrimeService:
    def __init__(self):
        self.client = httpx.AsyncClient(
            base_url=settings.crime_api_url,
            timeout=httpx.Timeout(connect=10.0, read=20.0, write=10.0, pool=10.0),
            headers={"User-Agent": "HomeScope/1.0", "Accept": "application/json"},
        )

    async def _latest_month(self) -> Optional[str]:
        """The API's data lags real-time by ~1-2 months; ask it which month is
        current rather than guessing. Returns 'YYYY-MM' or None."""
        try:
            resp = await self.client.get("/api/crime-last-updated")
            resp.raise_for_status()
            date_str = (resp.json() or {}).get("date")  # "YYYY-MM-01"
            if date_str:
                return date_str[:7]
        except Exception as e:  # noqa: BLE001 - non-fatal; caller can omit date
            logger.warning("crime_service.last_updated_failed", extra={"error": str(e)})
        return None

    async def fetch_uk_crime(self, lat: float, lng: float) -> CrimeReport:
        """Fetch and summarise street-level crime around a UK point. Raises on
        a hard HTTP/network failure — the pipeline stage catches and degrades."""
        month = await self._latest_month()
        params = {"lat": f"{lat:.5f}", "lng": f"{lng:.5f}"}
        if month:
            params["date"] = month

        resp = await self.client.get("/api/crimes-street/all-crime", params=params)
        resp.raise_for_status()
        crimes = resp.json() or []

        by_category: dict[str, int] = {}
        for c in crimes:
            cat = (c.get("category") or "other").replace("-", " ")
            by_category[cat] = by_category.get(cat, 0) + 1

        total = len(crimes)
        # Indicative 0-100 safety index for display only (NOT fed into the
        # category score): fewer street crimes in the ~1-mile radius over the
        # month → higher. Capped, hand-tuned heuristic.
        safety_index = round(max(0.0, 100.0 - min(total, 300) / 3.0), 1)

        return CrimeReport(
            source="uk_police",
            available=True,
            period=month,
            total=total,
            by_category=dict(
                sorted(by_category.items(), key=lambda kv: kv[1], reverse=True)
            ),
            safety_index=safety_index,
            radius_meters=_POLICE_API_RADIUS_M,
            note="Street-level crime from the UK Police API for the latest available month.",
        )

    async def close(self):
        await self.client.aclose()


crime_service = CrimeService()
