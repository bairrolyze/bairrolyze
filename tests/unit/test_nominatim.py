from unittest.mock import AsyncMock

import pytest

from geocoding.nominatim import NominatimService, _geocode_cache_key
from services import cache as cache_module


class TestGeocodeCacheKey:
    def test_lowercases_and_trims_address(self):
        key1 = _geocode_cache_key("  Rua Augusta 100  ", "PT")
        key2 = _geocode_cache_key("rua augusta 100", "pt")
        assert key1 == key2 == "geocode:pt:rua augusta 100"

    def test_different_country_codes_produce_different_keys(self):
        key_pt = _geocode_cache_key("Main St", "PT")
        key_es = _geocode_cache_key("Main St", "ES")
        assert key_pt != key_es


def _fake_response(payload):
    class _Resp:
        def raise_for_status(self):
            pass

        def json(self):
            return payload

    return _Resp()


NOMINATIM_RESULT = [
    {
        "lat": "38.7169",
        "lon": "-9.1399",
        "display_name": "Rua Augusta, Lisbon, Portugal",
        "importance": 0.8,
        "address": {"country": "Portugal", "city": "Lisbon"},
    }
]


@pytest.mark.asyncio
class TestGeocodeCaching:
    async def test_cache_hit_skips_http_call(self, monkeypatch):
        cached_payload = {
            "lat": 38.7169,
            "lng": -9.1399,
            "display_name": "Rua Augusta, Lisbon, Portugal",
            "country": "Portugal",
            "city": "Lisbon",
            "confidence": 0.8,
        }
        monkeypatch.setattr(
            cache_module.cache_service, "get", AsyncMock(return_value=cached_payload)
        )
        monkeypatch.setattr(cache_module.cache_service, "set", AsyncMock())

        svc = NominatimService()
        get_mock = AsyncMock()
        svc.client.get = get_mock

        result = await svc.geocode("Rua Augusta", "PT")

        assert result.display_name == "Rua Augusta, Lisbon, Portugal"
        get_mock.assert_not_called()

        await svc.close()

    async def test_cache_miss_calls_http_and_writes_cache(self, monkeypatch):
        monkeypatch.setattr(cache_module.cache_service, "get", AsyncMock(return_value=None))
        set_mock = AsyncMock()
        monkeypatch.setattr(cache_module.cache_service, "set", set_mock)

        svc = NominatimService()
        svc.client.get = AsyncMock(return_value=_fake_response(NOMINATIM_RESULT))

        result = await svc.geocode("Rua Augusta", "PT")

        assert result.lat == 38.7169
        set_mock.assert_awaited_once()
        cache_key_arg = set_mock.call_args.args[0]
        assert cache_key_arg == "geocode:pt:rua augusta"

        await svc.close()

    async def test_address_not_found_raises_value_error_and_does_not_cache(self, monkeypatch):
        monkeypatch.setattr(cache_module.cache_service, "get", AsyncMock(return_value=None))
        set_mock = AsyncMock()
        monkeypatch.setattr(cache_module.cache_service, "set", set_mock)

        svc = NominatimService()
        svc.client.get = AsyncMock(return_value=_fake_response([]))

        with pytest.raises(ValueError):
            await svc.geocode("Nonexistent Place Xyz", "PT")

        set_mock.assert_not_called()

        await svc.close()


AREA_SEARCH_RESULTS = [
    {
        "lat": "38.71", "lon": "-9.13", "class": "place", "type": "suburb",
        "display_name": "Alfama, Lisboa, Portugal",
        "namedetails": {"name": "Alfama"},
        "address": {"suburb": "Alfama", "city": "Lisboa", "country": "Portugal"},
    },
    {
        # A road — must be filtered out.
        "lat": "38.70", "lon": "-9.14", "class": "highway", "type": "residential",
        "display_name": "Rua Augusta, Lisboa, Portugal",
        "namedetails": {"name": "Rua Augusta"},
        "address": {"road": "Rua Augusta", "city": "Lisboa"},
    },
    {
        # A shop/POI — must be filtered out.
        "lat": "38.71", "lon": "-9.15", "class": "shop", "type": "supermarket",
        "display_name": "Pingo Doce, Lisboa, Portugal",
        "namedetails": {"name": "Pingo Doce"},
        "address": {"city": "Lisboa"},
    },
    {
        "lat": "41.15", "lon": "-8.61", "class": "place", "type": "city",
        "display_name": "Porto, Portugal",
        "namedetails": {"name": "Porto"},
        "address": {"city": "Porto", "country": "Portugal"},
    },
    {
        # Duplicate of Alfama — deduped.
        "lat": "38.71", "lon": "-9.13", "class": "place", "type": "neighbourhood",
        "display_name": "Alfama, Lisboa, Portugal",
        "namedetails": {"name": "Alfama"},
        "address": {"neighbourhood": "Alfama", "city": "Lisboa"},
    },
]


@pytest.mark.asyncio
class TestSearchAreas:
    async def test_filters_to_area_types_and_maps_fields(self, monkeypatch):
        monkeypatch.setattr(cache_module.cache_service, "get", AsyncMock(return_value=None))
        monkeypatch.setattr(cache_module.cache_service, "set", AsyncMock())

        svc = NominatimService()
        svc.client.get = AsyncMock(return_value=_fake_response(AREA_SEARCH_RESULTS))

        results = await svc.search_areas("al", "PT", limit=8)

        names = [r.name for r in results]
        # Road + shop dropped; Alfama deduped to one; Porto kept.
        assert names == ["Alfama", "Porto"]
        alfama = results[0]
        assert alfama.region == "Lisboa"
        assert alfama.lat == 38.71 and alfama.lng == -9.13
        assert alfama.type == "suburb"

        await svc.close()

    async def test_blank_query_returns_empty_without_http(self, monkeypatch):
        monkeypatch.setattr(cache_module.cache_service, "get", AsyncMock(return_value=None))
        svc = NominatimService()
        get_mock = AsyncMock()
        svc.client.get = get_mock

        assert await svc.search_areas("   ", "PT") == []
        get_mock.assert_not_called()

        await svc.close()

    async def test_cache_hit_skips_http(self, monkeypatch):
        cached = [{"name": "Alfama", "region": "Lisboa", "lat": 38.71, "lng": -9.13, "type": "suburb"}]
        monkeypatch.setattr(cache_module.cache_service, "get", AsyncMock(return_value=cached))
        svc = NominatimService()
        get_mock = AsyncMock()
        svc.client.get = get_mock

        results = await svc.search_areas("alf", "PT")
        assert results[0].name == "Alfama"
        get_mock.assert_not_called()

        await svc.close()
