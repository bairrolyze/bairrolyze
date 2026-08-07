"""Unit tests for the Redis-backed job store (services/job_store.py).

Uses an in-memory fake redis client (no real Redis server required) so
these run alongside the rest of tests/unit/ without external infra.
"""

import pytest

from services.job_store import (
    STAGE_DONE,
    STAGE_ERROR,
    STAGE_RUNNING,
    STATUS_DONE,
    STATUS_RUNNING,
    JobStore,
)


class FakeAsyncRedis:
    """Minimal in-memory stand-in for redis.asyncio.Redis covering only the
    get/set/close surface JobStore actually uses."""

    def __init__(self):
        self.store: dict[str, str] = {}
        self.last_ex = None

    async def get(self, key: str):
        return self.store.get(key)

    async def set(self, key: str, value: str, ex=None):
        self.store[key] = value
        self.last_ex = ex
        return True

    async def close(self):
        pass


@pytest.fixture
def store():
    js = JobStore(redis_url="redis://fake", ttl_seconds=3600)
    js._client = FakeAsyncRedis()
    return js


@pytest.mark.asyncio
class TestJobStore:
    async def test_create_job_sets_pending_status_and_empty_stages(self, store):
        job = await store.create_job("abc-123", {"address": "Rua Augusta, Lisboa"})

        assert job["analysis_id"] == "abc-123"
        assert job["status"] == "pending"
        assert job["partial_failure"] is False
        assert job["final"] is None
        assert job["progress"] == 0
        assert job["started_at"] is not None
        assert job["completed_at"] is None
        assert set(job["stages"].keys()) == {
            "address_found", "map_ready", "amenities_ready", "crime_ready", "score_ready", "summary_ready",
        }
        for stage in job["stages"].values():
            assert stage == {"status": "pending", "result": None, "error": None}

    async def test_get_job_roundtrips_created_job(self, store):
        await store.create_job("abc-123", {"address": "x"})
        fetched = await store.get_job("abc-123")

        assert fetched is not None
        assert fetched["analysis_id"] == "abc-123"

    async def test_get_job_returns_none_for_missing_id(self, store):
        assert await store.get_job("does-not-exist") is None

    async def test_update_stage_overwrites_not_appends(self, store):
        await store.create_job("abc-123", {"address": "x"})

        await store.update_stage("abc-123", "address_found", STAGE_RUNNING)
        job = await store.get_job("abc-123")
        assert job["stages"]["address_found"]["status"] == STAGE_RUNNING

        # Second write to the same stage must replace, not append/merge.
        await store.update_stage(
            "abc-123", "address_found", STAGE_DONE, result={"lat": 38.7, "lng": -9.1}
        )
        job = await store.get_job("abc-123")
        assert job["stages"]["address_found"] == {
            "status": STAGE_DONE,
            "result": {"lat": 38.7, "lng": -9.1},
            "error": None,
        }
        # Other stages remain untouched.
        assert job["stages"]["amenities_ready"]["status"] == "pending"

    async def test_update_stage_records_error(self, store):
        await store.create_job("abc-123", {"address": "x"})
        await store.update_stage("abc-123", "amenities_ready", STAGE_ERROR, error="amenity_fetch_failed: boom")

        job = await store.get_job("abc-123")
        assert job["stages"]["amenities_ready"]["status"] == STAGE_ERROR
        assert "boom" in job["stages"]["amenities_ready"]["error"]

    async def test_update_stage_on_missing_job_returns_none(self, store):
        result = await store.update_stage("ghost", "address_found", STAGE_DONE)
        assert result is None

    async def test_update_stage_bumps_progress_on_stage_done(self, store):
        await store.create_job("abc-123", {"address": "x"})
        job = await store.update_stage("abc-123", "address_found", STAGE_DONE, result={})
        assert job["progress"] == 10

        job = await store.update_stage("abc-123", "map_ready", STAGE_DONE, result={})
        assert job["progress"] == 25

        # RUNNING doesn't bump progress, only DONE does.
        job = await store.update_stage("abc-123", "amenities_ready", STAGE_RUNNING)
        assert job["progress"] == 25

    async def test_set_job_status_done_sets_progress_complete_and_completed_at(self, store):
        await store.create_job("abc-123", {"address": "x"})
        job = await store.set_job_status("abc-123", STATUS_DONE, partial_failure=False)
        assert job["progress"] == 100
        assert job["completed_at"] is not None

    async def test_set_job_status_updates_status_and_partial_failure(self, store):
        await store.create_job("abc-123", {"address": "x"})
        job = await store.set_job_status("abc-123", STATUS_RUNNING)
        assert job["status"] == STATUS_RUNNING

        job = await store.set_job_status("abc-123", STATUS_DONE, partial_failure=True)
        assert job["status"] == STATUS_DONE
        assert job["partial_failure"] is True

    async def test_set_job_status_writes_final_payload(self, store):
        await store.create_job("abc-123", {"address": "x"})
        final = {"id": "abc-123", "score": {"overall": 72.5}}
        job = await store.set_job_status("abc-123", STATUS_DONE, partial_failure=False, final=final)
        assert job["final"] == final

    async def test_set_job_status_on_missing_job_returns_none(self, store):
        assert await store.set_job_status("ghost", STATUS_DONE) is None

    async def test_write_uses_configured_ttl(self, store):
        await store.create_job("abc-123", {"address": "x"})
        assert store._client.last_ex == 3600

    async def test_updated_at_advances_on_write(self, store):
        job = await store.create_job("abc-123", {"address": "x"})
        created_updated_at = job["updated_at"]

        await store.update_stage("abc-123", "address_found", STAGE_DONE, result={})
        job = await store.get_job("abc-123")
        # updated_at is refreshed on every write (ISO timestamps compare lexicographically).
        assert job["updated_at"] >= created_updated_at
        assert job["created_at"] == created_updated_at or job["created_at"] <= job["updated_at"]
