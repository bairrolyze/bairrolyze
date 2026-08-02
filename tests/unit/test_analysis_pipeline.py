"""Unit tests for the background stage pipeline (services/analysis_pipeline.py).

address_found -> map_ready -> amenities_ready -> score_ready -> summary_ready
is called as a background task (address_found/map_ready both come from one
geocode() call, split for UI granularity). These tests verify: (1) the happy
path persists every stage and resolves the job to "done" with a final
payload, (2) a hard failure (geocode not resolving) records that stage's
error, marks downstream stages "blocked", and still resolves the job to
"done" with partial_failure=True instead of leaving it stuck "running", and
(3) a soft failure (amenities/Overpass erroring) degrades to an empty
amenity list and lets score/summary run anyway, matching the original
blocking /analyze endpoint's semantics.

`nominatim_service.geocode`, `overpass_service.fetch_amenities`, and
`calculate_location_score` are monkeypatched here as black boxes (per the
Phase B contract: this pipeline only calls them, it doesn't touch their
internals), so these tests don't depend on network access.
"""

from datetime import datetime
from unittest.mock import AsyncMock

import pytest

from models.schemas import AmenityModel, AnalyzeRequest, GeocodeResponse, LocationScore
import services.analysis_pipeline as pipeline
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


def _geo() -> GeocodeResponse:
    return GeocodeResponse(lat=38.7169, lng=-9.1399, display_name="Lisboa, Portugal", country="Portugal", city="Lisboa")


def _amenities() -> list:
    return [
        AmenityModel(
            id="a1", name="Escola Test", category="education", type="school",
            lat=38.717, lng=-9.14, distance_meters=100, walking_minutes=2,
        )
    ]


def _score() -> LocationScore:
    return LocationScore(overall=75.0, categories={}, profile="default", calculated_at=datetime.utcnow())


@pytest.fixture
def job_store(monkeypatch):
    store = JobStore(redis_url="redis://fake", ttl_seconds=3600)
    store._client = FakeAsyncRedis()
    monkeypatch.setattr(pipeline, "job_store", store)
    return store


@pytest.fixture
def request_obj():
    return AnalyzeRequest(address="Rua Augusta 150, Lisboa", country_code="PT", profile="default", radius=2000)


@pytest.mark.asyncio
class TestPipelineHappyPath:
    async def test_all_stages_done_and_job_resolves_with_final_payload(self, job_store, request_obj, monkeypatch):
        await job_store.create_job("job-1", request_obj.model_dump(mode="json"))

        monkeypatch.setattr(pipeline.nominatim_service, "geocode", AsyncMock(return_value=_geo()))
        monkeypatch.setattr(pipeline.overpass_service, "fetch_amenities", AsyncMock(return_value=_amenities()))
        monkeypatch.setattr(pipeline, "calculate_location_score", lambda amenities, profile: _score())
        monkeypatch.setattr(pipeline.settings, "openai_api_key", None)

        await pipeline.run_analysis_pipeline("job-1", request_obj)

        job = await job_store.get_job("job-1")
        assert job["status"] == "done"
        assert job["partial_failure"] is False
        assert job["progress"] == 100
        assert job["completed_at"] is not None
        assert job["stages"]["address_found"]["status"] == "done"
        assert job["stages"]["map_ready"]["status"] == "done"
        assert job["stages"]["map_ready"]["result"]["bbox"] is not None
        assert job["stages"]["amenities_ready"]["status"] == "done"
        assert job["stages"]["crime_ready"]["status"] == "done"
        assert job["stages"]["score_ready"]["status"] == "done"
        assert job["stages"]["summary_ready"]["status"] == "done"
        assert job["final"] is not None
        assert job["final"]["id"] == "job-1"
        assert job["final"]["score"]["overall"] == 75.0
        # PT address → no open crime API, so the crime stage resolves to the
        # OSM fallback (not a real fetch).
        assert job["final"]["crime"]["source"] == "osm"
        assert job["final"]["crime"]["available"] is False


@pytest.mark.asyncio
class TestPipelinePartialFailure:
    async def test_geocode_not_found_blocks_downstream_and_still_resolves_done(self, job_store, request_obj, monkeypatch):
        await job_store.create_job("job-2", request_obj.model_dump(mode="json"))

        monkeypatch.setattr(
            pipeline.nominatim_service, "geocode", AsyncMock(side_effect=ValueError("Address not found: x"))
        )

        await pipeline.run_analysis_pipeline("job-2", request_obj)

        job = await job_store.get_job("job-2")
        assert job["status"] == "done"  # never left stuck "running"
        assert job["partial_failure"] is True
        assert job["stages"]["address_found"]["status"] == "error"
        assert "not_found" in job["stages"]["address_found"]["error"]
        assert job["final"] is None
        # everything downstream is blocked, not silently left "pending" forever.
        assert job["stages"]["map_ready"]["status"] == "blocked"
        assert job["stages"]["crime_ready"]["status"] == "blocked"
        assert job["stages"]["score_ready"]["status"] == "blocked"
        assert job["stages"]["summary_ready"]["status"] == "blocked"

    async def test_amenities_failure_degrades_to_empty_list_and_completes(self, job_store, request_obj, monkeypatch):
        """Amenities is a soft dependency (matches the pre-job-pipeline
        /analyze behavior): an Overpass failure degrades to an empty amenity
        list rather than blocking score/ai_summary. A blocked pipeline here
        is worse for the user than a partial/degraded result — a 502-style
        dead end instead of a still-usable (if amenity-less) score.
        """
        await job_store.create_job("job-3", request_obj.model_dump(mode="json"))

        monkeypatch.setattr(pipeline.nominatim_service, "geocode", AsyncMock(return_value=_geo()))
        monkeypatch.setattr(
            pipeline.overpass_service, "fetch_amenities", AsyncMock(side_effect=RuntimeError("overpass down"))
        )
        monkeypatch.setattr(pipeline, "calculate_location_score", lambda amenities, profile: _score())
        monkeypatch.setattr(pipeline.settings, "openai_api_key", None)

        await pipeline.run_analysis_pipeline("job-3", request_obj)

        job = await job_store.get_job("job-3")
        assert job["status"] == "done"
        assert job["partial_failure"] is False
        # geocode succeeded and its result is preserved for progressive UI.
        assert job["stages"]["address_found"]["status"] == "done"
        assert job["stages"]["address_found"]["result"]["display_name"] == "Lisboa, Portugal"
        assert job["stages"]["map_ready"]["status"] == "done"
        # amenities degrades to an empty list rather than erroring out.
        assert job["stages"]["amenities_ready"]["status"] == "done"
        assert job["stages"]["amenities_ready"]["result"] == []
        # score and summary still run against the degraded (empty) amenities.
        assert job["stages"]["score_ready"]["status"] == "done"
        assert job["stages"]["summary_ready"]["status"] == "done"
        assert job["final"] is not None
        assert job["final"]["amenities"] == []

    async def test_ai_summary_falls_back_instead_of_failing_when_no_api_key(self, job_store, request_obj, monkeypatch):
        await job_store.create_job("job-4", request_obj.model_dump(mode="json"))

        monkeypatch.setattr(pipeline.nominatim_service, "geocode", AsyncMock(return_value=_geo()))
        monkeypatch.setattr(pipeline.overpass_service, "fetch_amenities", AsyncMock(return_value=_amenities()))
        monkeypatch.setattr(pipeline, "calculate_location_score", lambda amenities, profile: _score())
        monkeypatch.setattr(pipeline.settings, "openai_api_key", None)

        await pipeline.run_analysis_pipeline("job-4", request_obj)

        job = await job_store.get_job("job-4")
        assert job["status"] == "done"
        assert job["partial_failure"] is False
        assert job["stages"]["summary_ready"]["status"] == "done"
        assert isinstance(job["stages"]["summary_ready"]["result"], str)
        assert len(job["stages"]["summary_ready"]["result"]) > 0
