from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # App
    app_name: str = "HomeScope API"
    app_version: str = "1.0.0"
    debug: bool = False
    cors_origins: list[str] = ["*"]

    # Database
    database_url: str = "postgresql://homescope:homescope@localhost:5432/homescope"

    # Redis cache
    redis_url: str = "redis://localhost:6379/0"
    cache_ttl_seconds: int = 86400  # 24h

    # External APIs
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-4o-mini"
    openroute_api_key: Optional[str] = None

    # Nominatim
    nominatim_url: str = "https://nominatim.openstreetmap.org"
    nominatim_user_agent: str = "HomeScope/1.0 (contact@homescope.app)"

    # Overpass (using main instance — fallback if kumi.systems is slow)
    overpass_url: str = "https://overpass-api.de/api/interpreter"
    overpass_timeout: int = 90

    # OpenRouteService
    openroute_url: str = "https://api.openrouteservice.org"

    # Analysis defaults
    default_search_radius: float = 2000.0  # meters
    max_amenity_results: int = 100

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
