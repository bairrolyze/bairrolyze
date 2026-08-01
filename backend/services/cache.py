"""
Thin async Redis cache wrapper.

Used to cache expensive/rate-limited upstream lookups (Nominatim geocoding,
Overpass amenity queries). Redis is treated as a pure optimization: if it is
unreachable or misbehaves, every call degrades to a cache miss / no-op rather
than raising, so the app behaves exactly as it did before caching existed.
"""
import json
import logging
from typing import Any, Optional

import redis.asyncio as redis

from config.settings import settings

logger = logging.getLogger(__name__)


class CacheService:
    def __init__(self):
        self._redis: Optional[redis.Redis] = None
        self._connect_failed = False

    def _get_client(self) -> Optional[redis.Redis]:
        """Lazily create the Redis client. Returns None if a prior attempt
        to construct the client failed, so we don't retry pointlessly on
        every single request in a hard-down scenario within the same call."""
        if self._redis is not None:
            return self._redis
        if self._connect_failed:
            return None
        try:
            self._redis = redis.from_url(
                settings.redis_url,
                encoding="utf-8",
                decode_responses=True,
                socket_connect_timeout=2.0,
                socket_timeout=2.0,
            )
            return self._redis
        except Exception as e:
            logger.warning(f"Cache: failed to create Redis client: {e}")
            self._connect_failed = True
            return None

    async def get(self, key: str) -> Optional[dict]:
        """Return the cached value for `key`, or None on a miss or any
        Redis error (treated identically — never raises)."""
        client = self._get_client()
        if client is None:
            return None
        try:
            raw = await client.get(key)
        except Exception as e:
            logger.warning(f"Cache GET failed for key={key}: {e}")
            return None
        if raw is None:
            return None
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, TypeError) as e:
            logger.warning(f"Cache GET returned invalid JSON for key={key}: {e}")
            return None

    async def set(self, key: str, value: Any, ttl_seconds: int) -> None:
        """Best-effort write-through. Failures are logged and swallowed —
        a cache write failure must never break the calling request."""
        client = self._get_client()
        if client is None:
            return
        try:
            payload = json.dumps(value, default=str)
            await client.set(key, payload, ex=ttl_seconds)
        except Exception as e:
            logger.warning(f"Cache SET failed for key={key}: {e}")

    async def close(self) -> None:
        if self._redis is not None:
            try:
                await self._redis.aclose()
            except Exception:
                pass


cache_service = CacheService()
