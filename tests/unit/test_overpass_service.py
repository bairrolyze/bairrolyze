import math
from unittest.mock import AsyncMock

import pytest
from services.overpass_service import (
    OverpassService,
    _haversine_meters,
    _walking_minutes,
    _extract_name,
    _extract_type,
    _detect_category,
    _compute_bbox,
    _build_overpass_query,
    _amenities_cache_key,
)
from services import cache as cache_module
from services import overpass_service as overpass_module
from models.schemas import AmenityCategory


class TestHaversine:
    def test_same_point_is_zero(self):
        assert _haversine_meters(38.71, -9.14, 38.71, -9.14) == 0

    def test_known_distance_approx(self):
        # Lisbon to Porto is ~280km
        dist = _haversine_meters(38.7169, -9.1399, 41.1579, -8.6291)
        assert 270000 < dist < 290000

    def test_short_distance(self):
        dist = _haversine_meters(38.71, -9.14, 38.715, -9.14)
        assert 500 < dist < 600


class TestWalkingMinutes:
    def test_80_meters_is_one_minute(self):
        assert _walking_minutes(80) == 1

    def test_zero_meters_is_one_minute(self):
        assert _walking_minutes(0) == 1

    def test_800_meters_is_ten_minutes(self):
        assert _walking_minutes(800) == 10


class TestExtractName:
    def test_extracts_name_tag(self):
        element = {"tags": {"name": "Supermercado Continente", "amenity": "supermarket"}}
        assert _extract_name(element) == "Supermercado Continente"

    def test_falls_back_to_operator(self):
        element = {"tags": {"operator": "Pingo Doce"}}
        assert _extract_name(element) == "Pingo Doce"

    def test_unknown_when_no_tags(self):
        assert _extract_name({"tags": {}}) == "Unknown"


class TestExtractType:
    def test_amenity_type(self):
        element = {"tags": {"amenity": "school"}}
        assert _extract_type(element) == "school"

    def test_leisure_type(self):
        element = {"tags": {"leisure": "park"}}
        assert _extract_type(element) == "park"


class TestDetectCategory:
    def test_subway_is_transportation(self):
        assert _detect_category("subway_entrance") == AmenityCategory.transportation

    def test_school_is_education(self):
        assert _detect_category("school") == AmenityCategory.education

    def test_hospital_is_healthcare(self):
        assert _detect_category("hospital") == AmenityCategory.healthcare

    def test_supermarket_is_shopping(self):
        assert _detect_category("supermarket") == AmenityCategory.shopping

    def test_unknown_defaults_to_recreation(self):
        assert _detect_category("unknown_type") == AmenityCategory.recreation


class TestComputeBbox:
    def test_bbox_contains_center_point(self):
        south, west, north, east = _compute_bbox(38.71, -9.14, 1000)
        assert south < 38.71 < north
        assert west < -9.14 < east

    def test_bbox_is_expanded_beyond_raw_radius(self):
        # At the equator, 1 degree of latitude is ~111.32km, so a 1000m
        # radius (unexpanded) spans ~0.00898 degrees of latitude either way.
        # With the 1.2x expansion factor applied, the span should be ~20%
        # larger than that.
        south, west, north, east = _compute_bbox(0.0, 0.0, 1000)
        raw_lat_delta = 1000 / 111320.0
        expanded_lat_delta = north - 0.0
        assert expanded_lat_delta == pytest.approx(raw_lat_delta * 1.2, rel=1e-3)

    def test_longitude_span_widens_with_latitude(self):
        # 1 degree of longitude shrinks by cos(latitude), so at higher
        # latitudes the same radius should produce a *wider* longitude span
        # in degrees than at the equator.
        _, west_eq, _, east_eq = _compute_bbox(0.0, 0.0, 1000)
        _, west_60, _, east_60 = _compute_bbox(60.0, 0.0, 1000)
        lng_span_eq = east_eq - west_eq
        lng_span_60 = east_60 - west_60
        assert lng_span_60 == pytest.approx(lng_span_eq / math.cos(math.radians(60.0)), rel=1e-2)

    def test_near_pole_does_not_blow_up_or_divide_by_zero(self):
        # Portugal never gets anywhere near the poles, but the math must
        # stay well-defined (no ZeroDivisionError / inf / nan) if it's ever
        # called with an extreme latitude.
        south, west, north, east = _compute_bbox(89.99, 10.0, 2000)
        for value in (south, west, north, east):
            assert math.isfinite(value)
        assert -180.0 <= west <= east <= 180.0
        assert -90.0 <= south <= north <= 90.0

    def test_south_pole_does_not_blow_up(self):
        south, west, north, east = _compute_bbox(-89.99, 10.0, 2000)
        for value in (south, west, north, east):
            assert math.isfinite(value)

    def test_zero_radius_gives_degenerate_but_valid_bbox(self):
        south, west, north, east = _compute_bbox(38.71, -9.14, 0)
        assert south == pytest.approx(north)
        assert west == pytest.approx(east)

    def test_large_radius_clamped_to_valid_lat_lng_bounds(self):
        south, west, north, east = _compute_bbox(0.0, 0.0, 5_000_000)
        assert south >= -90.0
        assert north <= 90.0
        assert west >= -180.0
        assert east <= 180.0


class TestBuildOverpassQuery:
    def test_query_uses_bbox_not_around(self):
        query = _build_overpass_query(38.71, -9.14, 2000)
        assert "around" not in query
        assert "(" in query

    def test_query_contains_bbox_coordinates(self):
        south, west, north, east = _compute_bbox(38.71, -9.14, 2000)
        query = _build_overpass_query(38.71, -9.14, 2000)
        bbox_str = f"{south:.6f},{west:.6f},{north:.6f},{east:.6f}"
        assert bbox_str in query

    def test_query_has_one_node_and_way_clause_per_filter(self):
        from config.scoring_config import CATEGORY_CONFIG

        total_filters = sum(len(c["osm_filters"]) for c in CATEGORY_CONFIG.values())
        query = _build_overpass_query(38.71, -9.14, 2000)
        assert query.count("node[") == total_filters
        assert query.count("way[") == total_filters


class TestAmenitiesCacheKey:
    def test_rounds_coordinates_to_three_decimals(self):
        key = _amenities_cache_key(38.716123, -9.139456, 2000)
        assert key == "amenities:38.716:-9.139:2000"

    def test_nearby_coordinates_produce_same_key(self):
        # Two lookups within the same ~110m grid cell should dedupe.
        key1 = _amenities_cache_key(38.71601, -9.13901, 2000)
        key2 = _amenities_cache_key(38.71599, -9.13899, 2000)
        assert key1 == key2


def _fake_response(elements):
    class _Resp:
        def raise_for_status(self):
            pass

        def json(self):
            return {"elements": elements}

    return _Resp()


@pytest.mark.asyncio
class TestFetchAmenitiesRadiusFilter:
    async def test_drops_elements_outside_true_radius(self, monkeypatch):
        # Disable caching so the test exercises the live fetch path.
        monkeypatch.setattr(cache_module.cache_service, "get", AsyncMock(return_value=None))
        monkeypatch.setattr(cache_module.cache_service, "set", AsyncMock(return_value=None))

        lat, lng, radius = 38.71, -9.14, 500
        # near: well within 500m. far: inside the expanded bbox (1.2x) but
        # outside the true 500m radius requested by the caller.
        near_lat, near_lng = 38.712, -9.14  # ~222m away
        far_lat, far_lng = 38.7155, -9.14  # ~611m away, within the bbox margin

        elements = [
            {
                "type": "node",
                "lat": near_lat,
                "lon": near_lng,
                "tags": {"amenity": "school", "name": "Near School"},
            },
            {
                "type": "node",
                "lat": far_lat,
                "lon": far_lng,
                "tags": {"amenity": "school", "name": "Far School"},
            },
        ]

        svc = OverpassService()
        svc.client.post = AsyncMock(return_value=_fake_response(elements))

        results = await svc.fetch_amenities(lat, lng, radius)

        names = {a.name for a in results}
        assert "Near School" in names
        assert "Far School" not in names
        for a in results:
            assert a.distance_meters <= radius

        await svc.close()

    async def test_returns_cached_amenities_without_calling_client(self, monkeypatch):
        cached_payload = [
            {
                "id": "abc",
                "name": "Cached School",
                "category": "education",
                "type": "school",
                "lat": 38.71,
                "lng": -9.14,
                "distance_meters": 100,
                "walking_minutes": 2,
                "tags": None,
            }
        ]
        monkeypatch.setattr(
            cache_module.cache_service, "get", AsyncMock(return_value=cached_payload)
        )
        post_mock = AsyncMock()
        monkeypatch.setattr(cache_module.cache_service, "set", AsyncMock())

        svc = OverpassService()
        svc.client.post = post_mock

        results = await svc.fetch_amenities(38.71, -9.14, 2000)

        assert len(results) == 1
        assert results[0].name == "Cached School"
        post_mock.assert_not_called()

        await svc.close()
