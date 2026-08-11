"""Redis-backed 'popular areas' aggregation for region-scoped discovery.

Every successful geocode records one search against the (country, region,
area) it resolved to. Counts live in a Redis sorted set per region:

    hs:pop:area:{country_code}:{region_norm}   ZSET  member=area  score=count

`GET /api/v1/popular?country=&region=` reads the top members back. This is the
backend half of the "Popular Searches" feature — the mobile app blends it with
its curated fallback list (which covers cold-start / sparse regions).

Deliberately Redis, not Postgres: the analyze pipeline already depends on Redis
(job_store) and the SQL layer is optional/half-wired. Counting is a single
ZINCRBY per search — cheap, and it never blocks or fails the analyze pipeline
(the caller fires it best-effort).

Privacy: only aggregate counts per named area are stored — never individual
queries, coordinates, addresses, or user identifiers.
"""

import logging
from typing import List, Optional, Tuple

import redis.asyncio as redis

from config.settings import settings

logger = logging.getLogger(__name__)

AREA_KEY_PREFIX = "hs:pop:area:"

# Sorted-set keys are refreshed to this TTL on every write, so a region that
# stops being searched eventually expires instead of pinning stale "popular"
# data forever. ~120 days.
POPULARITY_TTL_SECONDS = 120 * 24 * 60 * 60


def _norm(value: str) -> str:
    return value.strip().lower()


def _area_key(country_code: str, region: str) -> str:
    return f"{AREA_KEY_PREFIX}{_norm(country_code)}:{_norm(region)}"


class PopularityStore:
    def __init__(self, redis_url: Optional[str] = None):
        self._redis_url = redis_url or settings.redis_url
        self._client: Optional["redis.Redis"] = None

    @property
    def client(self) -> "redis.Redis":
        if self._client is None:
            self._client = redis.from_url(self._redis_url, decode_responses=True)
        return self._client

    async def record_search(
        self,
        country_code: Optional[str],
        region: Optional[str],
        area: Optional[str],
    ) -> None:
        """Best-effort: increment the (country, region, area) counter.

        No-ops (rather than raising) when the geocode lacked region/area
        granularity or Redis is unavailable — this is called from the analyze
        pipeline and must never break it.
        """
        if not country_code or not region or not area:
            return
        region = region.strip()
        area = area.strip()
        if not region or not area:
            return
        # Skip when the "area" is just the region repeated (no sub-city detail).
        if _norm(area) == _norm(region):
            return
        key = _area_key(country_code, region)
        try:
            async with self.client.pipeline(transaction=False) as pipe:
                pipe.zincrby(key, 1, area)
                pipe.expire(key, POPULARITY_TTL_SECONDS)
                await pipe.execute()
        except Exception as exc:  # noqa: BLE001 - popularity is non-critical
            logger.warning("popularity_store.record_failed", extra={"error": str(exc)})

    async def top_areas(
        self,
        country_code: str,
        region: str,
        limit: int = 8,
    ) -> List[Tuple[str, int]]:
        """Most-searched areas within a region, as (area, count) descending."""
        key = _area_key(country_code, region)
        try:
            rows = await self.client.zrevrange(key, 0, max(0, limit - 1), withscores=True)
        except Exception as exc:  # noqa: BLE001 - degrade to empty, not an error
            logger.warning("popularity_store.read_failed", extra={"error": str(exc)})
            return []
        return [(member, int(score)) for member, score in rows]

    async def close(self) -> None:
        if self._client is not None:
            await self._client.close()
            self._client = None


popularity_store = PopularityStore()
