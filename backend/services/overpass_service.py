import httpx
import math
import urllib.parse
from typing import List, Dict, Any
from uuid import uuid4

from config.settings import settings
from config.scoring_config import CATEGORY_CONFIG, OSM_TYPE_TO_CATEGORY
from models.schemas import AmenityModel, AmenityCategory


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


def _build_overpass_query(lat: float, lng: float, radius: float) -> str:
    filters = []
    for cat_config in CATEGORY_CONFIG.values():
        for f in cat_config["osm_filters"]:
            filters.append(f'node{f}(around:{radius},{lat},{lng});')
            filters.append(f'way{f}(around:{radius},{lat},{lng});')

    query = f"""
[out:json][timeout:{settings.overpass_timeout}];
(
  {''.join(filters)}
);
out center tags;
"""
    return query.strip()


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
        query = _build_overpass_query(lat, lng, radius)

        # Send as form data (key=value format)
        try:
            response = await self.client.post(
                settings.overpass_url,
                data={"data": query},
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            response.raise_for_status()
            data = response.json()
        except httpx.HTTPStatusError as e:
            # Log the error details
            print(f"Overpass API error: {e.response.status_code}")
            print(f"Response body: {e.response.text[:500]}")
            raise
        except Exception as e:
            print(f"Overpass request failed: {str(e)}")
            raise

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
        return amenities[: settings.max_amenity_results]

    async def close(self):
        await self.client.aclose()


overpass_service = OverpassService()
