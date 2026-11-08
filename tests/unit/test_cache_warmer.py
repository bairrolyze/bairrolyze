"""Unit tests for services/cache_warmer.py.

nominatim_service.geocode, overpass_service.fetch_amenities, and
popularity_store are monkeypatched as black boxes — these tests verify the
warmer's own orchestration (which areas it warms, how failures are counted),
not the services it calls.
"""

from datetime import datetime
from unittest.mock import AsyncMock

import pytest

from models.schemas import GeocodeResponse
import services.cache_warmer as cache_warmer


def _geo(lat=38.7169, lng=-9.1399) -> GeocodeResponse:
    return GeocodeResponse(lat=lat, lng=lng, display_name="Lisboa, Portugal", country="Portugal", city="Lisboa")


@pytest.mark.asyncio
class TestWarmArea:
    async def test_geocodes_then_fetches_amenities_with_the_resolved_coordinates(self, monkeypatch):
        geocode_mock = AsyncMock(return_value=_geo(lat=38.71, lng=-9.14))
        fetch_mock = AsyncMock(return_value=[])
        monkeypatch.setattr(cache_warmer.nominatim_service, "geocode", geocode_mock)
        monkeypatch.setattr(cache_warmer.overpass_service, "fetch_amenities", fetch_mock)

        ok = await cache_warmer.warm_area("PT", "Lisboa", "Alfama")

        assert ok is True
        geocode_mock.assert_awaited_once_with("Alfama, Lisboa", "PT")
        fetch_mock.assert_awaited_once_with(lat=38.71, lng=-9.14, radius=cache_warmer.DEFAULT_WARM_RADIUS)

    async def test_geocode_failure_returns_false_without_calling_overpass(self, monkeypatch):
        geocode_mock = AsyncMock(side_effect=ValueError("not found"))
        fetch_mock = AsyncMock()
        monkeypatch.setattr(cache_warmer.nominatim_service, "geocode", geocode_mock)
        monkeypatch.setattr(cache_warmer.overpass_service, "fetch_amenities", fetch_mock)

        ok = await cache_warmer.warm_area("PT", "Lisboa", "Nowhere")

        assert ok is False
        fetch_mock.assert_not_awaited()

    async def test_amenities_failure_returns_false(self, monkeypatch):
        monkeypatch.setattr(cache_warmer.nominatim_service, "geocode", AsyncMock(return_value=_geo()))
        monkeypatch.setattr(
            cache_warmer.overpass_service, "fetch_amenities", AsyncMock(side_effect=RuntimeError("overpass down"))
        )

        ok = await cache_warmer.warm_area("PT", "Lisboa", "Alfama")

        assert ok is False


@pytest.mark.asyncio
class TestWarmPopularAreas:
    async def test_warms_top_areas_across_every_tracked_region(self, monkeypatch):
        monkeypatch.setattr(
            cache_warmer.popularity_store,
            "list_tracked_regions",
            AsyncMock(return_value=[("pt", "lisboa"), ("pt", "porto")]),
        )

        async def fake_top_areas(country_code, region, limit=10):
            return {"lisboa": [("Alfama", 5)], "porto": [("Bonfim", 2)]}[region]

        monkeypatch.setattr(cache_warmer.popularity_store, "top_areas", fake_top_areas)
        monkeypatch.setattr(cache_warmer, "warm_area", AsyncMock(return_value=True))

        result = await cache_warmer.warm_popular_areas()

        assert result["warmed"] == ["Alfama, lisboa (pt)", "Bonfim, porto (pt)"]
        assert result["failed"] == []

    async def test_failed_warms_are_reported_separately(self, monkeypatch):
        monkeypatch.setattr(
            cache_warmer.popularity_store,
            "list_tracked_regions",
            AsyncMock(return_value=[("pt", "lisboa")]),
        )
        monkeypatch.setattr(
            cache_warmer.popularity_store,
            "top_areas",
            AsyncMock(return_value=[("Alfama", 5), ("Chiado", 3)]),
        )
        monkeypatch.setattr(cache_warmer, "warm_area", AsyncMock(side_effect=[True, False]))

        result = await cache_warmer.warm_popular_areas()

        assert result["warmed"] == ["Alfama, lisboa (pt)"]
        assert result["failed"] == ["Chiado, lisboa (pt)"]

    async def test_no_tracked_regions_warms_nothing(self, monkeypatch):
        monkeypatch.setattr(
            cache_warmer.popularity_store, "list_tracked_regions", AsyncMock(return_value=[])
        )

        result = await cache_warmer.warm_popular_areas()

        assert result == {"warmed": [], "failed": []}
