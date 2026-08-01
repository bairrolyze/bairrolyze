"""Unit tests for SSE event framing (services/sse.py::stream_job_events).

Verifies: correct `event: ...\\ndata: ...\\n\\n` framing, one event per
observed stage/job-status change (not spammed every poll tick), a
terminal `complete` event when the job reaches "done", a 404-equivalent
`error` event when the job disappears from the store (expired/missing),
and the max-duration safety cutoff closing the stream with a `timeout`
event instead of hanging forever.
"""

import json

import pytest

from services import sse as sse_module
from services.job_store import JobStore


class FakeAsyncRedis:
    def __init__(self):
        self.store: dict = {}

    async def get(self, key: str):
        return self.store.get(key)

    async def set(self, key: str, value: str, ex=None):
        self.store[key] = value
        return True

    async def close(self):
        pass


def _parse_events(chunks: list) -> list:
    """Parse raw SSE text chunks into a list of {event, data} dicts."""
    events = []
    for chunk in chunks:
        lines = chunk.strip("\n").split("\n")
        event_line = next(l for l in lines if l.startswith("event: "))
        data_line = next(l for l in lines if l.startswith("data: "))
        events.append({"event": event_line[len("event: "):], "data": json.loads(data_line[len("data: "):])})
    return events


@pytest.fixture
def job_store():
    store = JobStore(redis_url="redis://fake", ttl_seconds=3600)
    store._client = FakeAsyncRedis()
    return store


@pytest.mark.asyncio
class TestStreamJobEvents:
    async def test_frames_each_yielded_chunk_as_valid_sse(self, job_store, monkeypatch):
        monkeypatch.setattr(sse_module, "job_store", job_store)
        await job_store.create_job("job-1", {"address": "x"})
        await job_store.set_job_status("job-1", "done", partial_failure=False, final={"id": "job-1"})

        chunks = []
        async for chunk in sse_module.stream_job_events("job-1", poll_interval_seconds=0.01, max_stream_seconds=5):
            chunks.append(chunk)

        assert len(chunks) >= 1
        for chunk in chunks:
            assert chunk.startswith("event: ")
            assert "\ndata: " in chunk
            assert chunk.endswith("\n\n")

    async def test_emits_complete_event_and_closes_when_job_done(self, job_store, monkeypatch):
        monkeypatch.setattr(sse_module, "job_store", job_store)
        await job_store.create_job("job-2", {"address": "x"})
        await job_store.update_stage("job-2", "geocode", "done", result={"lat": 1})
        await job_store.set_job_status("job-2", "done", partial_failure=False, final={"id": "job-2"})

        chunks = [c async for c in sse_module.stream_job_events("job-2", poll_interval_seconds=0.01, max_stream_seconds=5)]
        events = _parse_events(chunks)

        assert events[-1]["event"] == "complete"
        assert events[-1]["data"]["status"] == "done"
        assert events[-1]["data"]["final"] == {"id": "job-2"}
        # Stage change for geocode should have been emitted before completing.
        stage_events = [e for e in events if e["event"] == "stage" and e["data"]["stage"] == "geocode"]
        assert any(e["data"]["status"] == "done" for e in stage_events)

    async def test_only_emits_events_on_status_change_not_every_poll(self, job_store, monkeypatch):
        monkeypatch.setattr(sse_module, "job_store", job_store)
        await job_store.create_job("job-3", {"address": "x"})
        # Job status goes straight to "done" and never changes again, so
        # repeated polls (if the generator polled more than once before
        # noticing "done") must not duplicate the job_status event.
        await job_store.set_job_status("job-3", "done", partial_failure=False, final={"id": "job-3"})

        chunks = [c async for c in sse_module.stream_job_events("job-3", poll_interval_seconds=0.01, max_stream_seconds=5)]
        events = _parse_events(chunks)

        job_status_events = [e for e in events if e["event"] == "job_status"]
        assert len(job_status_events) == 1

    async def test_yields_error_event_when_job_missing(self, job_store, monkeypatch):
        monkeypatch.setattr(sse_module, "job_store", job_store)

        chunks = [c async for c in sse_module.stream_job_events("does-not-exist", poll_interval_seconds=0.01, max_stream_seconds=5)]
        events = _parse_events(chunks)

        assert len(events) == 1
        assert events[0]["event"] == "error"

    async def test_stops_after_max_stream_seconds_with_timeout_event(self, job_store, monkeypatch):
        monkeypatch.setattr(sse_module, "job_store", job_store)
        await job_store.create_job("job-4", {"address": "x"})
        # Job intentionally never reaches "done" — simulates a stuck job.

        chunks = [
            c
            async for c in sse_module.stream_job_events("job-4", poll_interval_seconds=0.01, max_stream_seconds=0.03)
        ]
        events = _parse_events(chunks)

        assert events[-1]["event"] == "timeout"
