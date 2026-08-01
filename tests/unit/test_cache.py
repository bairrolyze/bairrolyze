import pytest

from services.cache import CacheService


class _FakeRedis:
    """Minimal in-memory stand-in for redis.asyncio.Redis, just enough to
    exercise CacheService's get/set/close contract without a real server."""

    def __init__(self):
        self.store = {}
        self.ttls = {}

    async def get(self, key):
        return self.store.get(key)

    async def set(self, key, value, ex=None):
        self.store[key] = value
        self.ttls[key] = ex

    async def aclose(self):
        pass


class _BrokenRedis:
    """Simulates a Redis instance that is reachable but errors on every
    command (e.g. auth failure, connection reset mid-command)."""

    async def get(self, key):
        raise ConnectionError("boom")

    async def set(self, key, value, ex=None):
        raise ConnectionError("boom")

    async def aclose(self):
        pass


@pytest.mark.asyncio
class TestCacheServiceHappyPath:
    async def test_set_then_get_roundtrips_json(self, monkeypatch):
        svc = CacheService()
        fake = _FakeRedis()
        monkeypatch.setattr(svc, "_get_client", lambda: fake)

        await svc.set("k1", {"lat": 38.71, "lng": -9.14}, ttl_seconds=60)
        result = await svc.get("k1")

        assert result == {"lat": 38.71, "lng": -9.14}
        assert fake.ttls["k1"] == 60

    async def test_get_miss_returns_none(self, monkeypatch):
        svc = CacheService()
        fake = _FakeRedis()
        monkeypatch.setattr(svc, "_get_client", lambda: fake)

        assert await svc.get("missing-key") is None

    async def test_get_invalid_json_returns_none_not_raise(self, monkeypatch):
        svc = CacheService()
        fake = _FakeRedis()
        fake.store["bad"] = "{not valid json"
        monkeypatch.setattr(svc, "_get_client", lambda: fake)

        assert await svc.get("bad") is None


@pytest.mark.asyncio
class TestCacheServiceGracefulDegradation:
    async def test_get_returns_none_when_client_unavailable(self, monkeypatch):
        svc = CacheService()
        monkeypatch.setattr(svc, "_get_client", lambda: None)

        assert await svc.get("any-key") is None

    async def test_set_is_a_noop_when_client_unavailable(self, monkeypatch):
        svc = CacheService()
        monkeypatch.setattr(svc, "_get_client", lambda: None)

        # Must not raise.
        await svc.set("any-key", {"a": 1}, ttl_seconds=60)

    async def test_get_swallows_redis_errors(self, monkeypatch):
        svc = CacheService()
        monkeypatch.setattr(svc, "_get_client", lambda: _BrokenRedis())

        assert await svc.get("k") is None

    async def test_set_swallows_redis_errors(self, monkeypatch):
        svc = CacheService()
        monkeypatch.setattr(svc, "_get_client", lambda: _BrokenRedis())

        # Must not raise even though the underlying client errors.
        await svc.set("k", {"a": 1}, ttl_seconds=60)

    async def test_connect_failure_is_cached_as_a_permanent_miss(self, monkeypatch):
        svc = CacheService()

        def _boom():
            raise ConnectionError("redis unreachable")

        # Patch the module-level redis.from_url that _get_client calls.
        import services.cache as cache_module

        monkeypatch.setattr(cache_module.redis, "from_url", lambda *a, **kw: _boom())

        assert await svc.get("k") is None
        assert svc._connect_failed is True
        # Second call shouldn't attempt to reconnect (from_url would raise again
        # if it were called, so a clean second `get` proves it wasn't called).
        assert await svc.get("k") is None
