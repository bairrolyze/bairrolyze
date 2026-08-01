import httpx
import logging
import math
import time
from typing import List, Dict, Any, Optional, Tuple
from uuid import uuid4

from config.settings import settings
from config.scoring_config import CATEGORY_CONFIG, OSM_TYPE_TO_CATEGORY
from models.schemas import AmenityModel, AmenityCategory
from services.cache import cache_service

logger = logging.getLogger(__name__)

AMENITIES_CACHE_TTL_SECONDS = 604800  # 7 days

# Bbox is derived from the requested radius expanded by this factor, since a
# square bbox has to fully contain the circle we actually care about. Results
# outside the true radius are dropped by the haversine post-filter below.
BBOX_EXPAND_FACTOR = 1.2

METERS_PER_DEGREE_LAT = 111320.0  # ~111.32km per degree of latitude


def _haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> int:
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return int(R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))


def _walking_minutes(meters: int) -> int:
    return max(1, round(meters / 80))  # ~80m/min walking speed


def _extract_name(element: Dict[str, Any]) -> str:
    tags = element.get("tags", {})
    return (
        tags.get("name")
        or tags.get("name:en")
        or tags.get("ref")
        or tags.get("operator")
        or tags.get("amenity")
        or tags.get("leisure")
        or tags.get("railway")
        or tags.get("highway")
        or "Unknown"
    )


def _extract_type(element: Dict[str, Any]) -> str:
    tags = element.get("tags", {})
    for key in ["amenity", "leisure", "railway", "highway", "shop", "public_transport"]:
        if key in tags:
            return tags[key]
    return "place"


def _detect_category(osm_type: str) -> AmenityCategory:
    cat = OSM_TYPE_TO_CATEGORY.get(osm_type)
    if cat:
        return AmenityCategory(cat)
    return AmenityCategory.recreation


def _compute_bbox(
    lat: float, lng: float, radius: float, expand_factor: float = BBOX_EXPAND_FACTOR
) -> Tuple[float, float, float, float]:
    """Derive a (south, west, north, east) bounding box that fully contains a
    circle of `radius` meters around (lat, lng), expanded by `expand_factor`
    to give the downstream haversine filter a safety margin.

    1 degree of latitude is ~111.32km everywhere. 1 degree of longitude is
    ~111.32km * cos(latitude), shrinking to 0 at the poles — so we clamp
    cos(latitude) away from zero to avoid the longitude span blowing up to
    +/-180 (or dividing by zero outright) for extreme/edge-case latitudes.
    """
    adjusted_radius = max(radius, 0.0) * expand_factor

    lat_delta = adjusted_radius / METERS_PER_DEGREE_LAT

    # Clamp the latitude used for the cosine so we never divide by ~0 near
    # the poles (not a realistic case for Portugal, but keeps the math safe).
    lat_for_cos = max(-89.9, min(89.9, lat))
    cos_lat = max(math.cos(math.radians(lat_for_cos)), 1e-6)
    lng_delta = adjusted_radius / (METERS_PER_DEGREE_LAT * cos_lat)

    south = max(-90.0, lat - lat_delta)
    north = min(90.0, lat + lat_delta)
    west = max(-180.0, lng - lng_delta)
    east = min(180.0, lng + lng_delta)

    return south, west, north, east


def _build_overpass_query(lat: float, lng: float, radius: float) -> str:
    south, west, north, east = _compute_bbox(lat, lng, radius)
    bbox = f"{south:.6f},{west:.6f},{north:.6f},{east:.6f}"

    filters = []
    for cat_config in CATEGORY_CONFIG.values():
        for f in cat_config["osm_filters"]:
            filters.append(f'node{f}({bbox});')
            filters.append(f'way{f}({bbox});')

    query = f"""
[out:json][timeout:{settings.overpass_timeout}];
(
  {''.join(filters)}
);
out center tags;
"""
    return query.strip()


def _amenities_cache_key(lat: float, lng: float, radius: float) -> str:
    return f"amenities:{round(lat, 3)}:{round(lng, 3)}:{radius}"


class OverpassService:
    def __init__(self):
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                connect=10.0,
                read=settings.overpass_timeout + 10.0,
                write=10.0,
                pool=10.0
            ),
            headers={
                "User-Agent": "HomeScope/1.0",
                "Accept": "application/json"
            }
        )

    async def fetch_amenities(
        self, lat: float, lng: float, radius: float = 2000.0
    ) -> List[AmenityModel]:
        cache_key = _amenities_cache_key(lat, lng, radius)
        cached = await cache_service.get(cache_key)
        if cached is not None:
            logger.info(f"Amenities cache HIT key={cache_key} count={len(cached)}")
            return [AmenityModel(**item) for item in cached]
        logger.info(f"Amenities cache MISS key={cache_key}")

        query = _build_overpass_query(lat, lng, radius)

        # Send as form data (key=value format)
        start = time.monotonic()
        try:
            response = await self.client.post(
                settings.overpass_url,
                data={"data": query},
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            response.raise_for_status()
            data = response.json()
        except httpx.HTTPStatusError as e:
            duration_ms = (time.monotonic() - start) * 1000
            logger.warning(
                f"Overpass API error after {duration_ms:.0f}ms: "
                f"status={e.response.status_code} body={e.response.text[:500]!r}"
            )
            raise
        except Exception as e:
            duration_ms = (time.monotonic() - start) * 1000
            logger.warning(f"Overpass request failed after {duration_ms:.0f}ms: {e}")
            raise
        duration_ms = (time.monotonic() - start) * 1000
        logger.info(
            f"Overpass query took {duration_ms:.0f}ms lat={lat} lng={lng} radius={radius}"
        )

        amenities: List[AmenityModel] = []
        seen_names: set = set()

        for element in data.get("elements", []):
            name = _extract_name(element)
            if name == "Unknown":
                continue

            # Deduplicate by name + type
            dedup_key = f"{name}_{element.get('tags', {}).get('amenity', '')}"
            if dedup_key in seen_names:
                continue
            seen_names.add(dedup_key)

            # Get coordinates
            if element["type"] == "node":
                elat = element["lat"]
                elng = element["lon"]
            elif element["type"] == "way" and "center" in element:
                elat = element["center"]["lat"]
                elng = element["center"]["lon"]
            else:
                continue

            osm_type = _extract_type(element)
            category = _detect_category(osm_type)
            distance = _haversine_meters(lat, lng, elat, elng)

            # The bbox is a square that over-covers the requested circle, so
            # drop anything outside the true radius before it ever gets
            # scored (Overpass has no way to filter this itself with an
            # indexed bbox query).
            if distance > radius:
                continue

            walking = _walking_minutes(distance)

            amenities.append(
                AmenityModel(
                    id=str(uuid4()),
                    name=name,
                    category=category,
                    type=osm_type,
                    lat=elat,
                    lng=elng,
                    distance_meters=distance,
                    walking_minutes=walking,
                    tags=element.get("tags"),
                )
            )

        # Sort by distance
        amenities.sort(key=lambda a: a.distance_meters or 99999)
        amenities = amenities[: settings.max_amenity_results]

        await cache_service.set(
            cache_key,
            [a.model_dump() for a in amenities],
            AMENITIES_CACHE_TTL_SECONDS,
        )

        return amenities

    async def close(self):
        await self.client.aclose()


overpass_service = OverpassService()
