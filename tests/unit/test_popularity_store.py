"""Unit tests for the Redis-backed popularity store
(services/popularity_store.py).

Uses an in-memory fake redis client (no real Redis server required) covering
only the sorted-set surface the store actually uses.
"""

import pytest

from services.popularity_store import PopularityStore


class FakePipeline:
    def __init__(self, parent: "FakeAsyncRedis"):
        self.parent = parent
        self.ops: list = []

    def zincrby(self, key, amount, member):
        self.ops.append(("zincrby", key, amount, member))
        return self

    def expire(self, key, ttl):
        self.ops.append(("expire", key, ttl))
        return self

    async def execute(self):
        for op in self.ops:
            if op[0] == "zincrby":
                _, key, amount, member = op
                self.parent.zsets.setdefault(key, {})
                self.parent.zsets[key][member] = self.parent.zsets[key].get(member, 0) + amount
            elif op[0] == "expire":
                _, key, ttl = op
                self.parent.expires[key] = ttl
        self.ops.clear()
        return True

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False


class FakeAsyncRedis:
    def __init__(self):
        self.zsets: dict[str, dict[str, float]] = {}
        self.expires: dict[str, int] = {}

    def pipeline(self, transaction=False):
        return FakePipeline(self)

    async def zrevrange(self, key, start, stop, withscores=False):
        members = sorted(
            self.zsets.get(key, {}).items(), key=lambda kv: kv[1], reverse=True
        )
        sliced = members[start : stop + 1]
        if withscores:
            return [(m, s) for m, s in sliced]
        return [m for m, _ in sliced]

    async def close(self):
        pass


@pytest.fixture
def store():
    ps = PopularityStore(redis_url="redis://fake")
    ps._client = FakeAsyncRedis()
    return ps


@pytest.mark.asyncio
class TestPopularityStore:
    async def test_record_and_top_areas_ranked_desc(self, store):
        for _ in range(3):
            await store.record_search("PT", "Lisboa", "Alfama")
        await store.record_search("PT", "Lisboa", "Chiado")

        top = await store.top_areas("PT", "Lisboa")
        assert top == [("Alfama", 3), ("Chiado", 1)]

    async def test_region_key_is_country_and_region_normalized(self, store):
        # Different casing / whitespace count into the same bucket.
        await store.record_search("pt", "  Lisboa ", "Alfama")
        await store.record_search("PT", "lisboa", "Alfama")

        top = await store.top_areas("PT", "LISBOA")
        assert top == [("Alfama", 2)]

    async def test_missing_region_or_area_is_noop(self, store):
        await store.record_search("PT", None, "Alfama")
        await store.record_search("PT", "Lisboa", None)
        await store.record_search(None, "Lisboa", "Alfama")
        await store.record_search("PT", "Lisboa", "   ")

        assert await store.top_areas("PT", "Lisboa") == []

    async def test_area_equal_to_region_is_skipped(self, store):
        # A city-only geocode (area == region) carries no sub-city signal.
        await store.record_search("PT", "Lisboa", "lisboa")
        assert await store.top_areas("PT", "Lisboa") == []

    async def test_limit_caps_results(self, store):
        for i in range(10):
            for _ in range(10 - i):
                await store.record_search("PT", "Porto", f"Area{i}")

        top = await store.top_areas("PT", "Porto", limit=3)
        assert [name for name, _ in top] == ["Area0", "Area1", "Area2"]
        assert len(top) == 3

    async def test_expire_refreshed_on_write(self, store):
        await store.record_search("PT", "Lisboa", "Alfama")
        key = "hs:pop:area:pt:lisboa"
        assert store._client.expires.get(key) is not None
