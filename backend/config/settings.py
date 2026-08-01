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

    # Job store (background analyze pipeline) — jobs are transient, not
    # permanent cache; keep this separate from cache_ttl_seconds above.
    job_ttl_seconds: int = 3600  # 1h
    job_stream_poll_seconds: float = 0.4
    job_stream_max_seconds: int = 60

    # External APIs
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-4o-mini"
    openroute_api_key: Optional[str] = None

    # Nominatim
    nominatim_url: str = "https://nominatim.openstreetmap.org"
    nominatim_user_agent: str = "HomeScope/1.0 (contact@homescope.app)"

    # Overpass (using main instance — fallback if kumi.systems is slow)
    overpass_url: str = "https://overpass-api.de/api/interpreter"
    # Bbox queries (see overpass_service._build_overpass_query) are indexed
    # and fast, so a long worst-case timeout is no longer needed — a slow
    # response now almost certainly means the upstream is genuinely down,
    # and /api/v1/analyze degrades gracefully rather than hanging on it.
    overpass_timeout: int = 15

    # OpenRouteService
    openroute_url: str = "https://api.openrouteservice.org"

    # Analysis defaults
    default_search_radius: float = 2000.0  # meters
    max_amenity_results: int = 100

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
