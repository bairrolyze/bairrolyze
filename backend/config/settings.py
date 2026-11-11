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

    # UK Police API (data.police.uk) — free, no key, UK-only crime data.
    crime_api_url: str = "https://data.police.uk"

    # Overpass (using main instance — fallback if kumi.systems is slow)
    overpass_url: str = "https://overpass-api.de/api/interpreter"
    # Bbox queries (see overpass_service._build_overpass_query) are indexed
    # and fast, so a long worst-case timeout is no longer needed — a slow
    # response now almost certainly means the upstream is genuinely at
    # capacity or down. Kept short so the 3-endpoint failover in
    # overpass_service (one attempt each, no same-endpoint retry) surfaces a
    # failure in well under a minute instead of ~150s worst case —
    # amenities_ready is now a hard failure (blocks score/summary), so how
    # fast it fails directly bounds how long a user waits for "it didn't
    # work" instead of a result.
    overpass_timeout: int = 8

    # Self-hosted Overpass instance (Portugal-only extract), tried only after
    # all public mirrors fail — see OVERPASS_MIRRORS in overpass_service.py.
    # Set via env var so the URL (a Cloudflare Tunnel hostname that can change
    # on restart) never needs a code change/redeploy to update, and is simply
    # absent/skipped when unset.
    overpass_self_hosted_url: Optional[str] = None

    # OpenRouteService
    openroute_url: str = "https://api.openrouteservice.org"

    # Analysis defaults
    default_search_radius: float = 2000.0  # meters
    max_amenity_results: int = 100

    # Admin endpoints (api/routes/admin.py) — gated by the X-API-Key header
    # matching this value. None disables every admin route (verify_admin_api_key
    # returns 500 rather than silently accepting an unprotected request).
    admin_api_key: Optional[str] = None

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"  # .env carries deploy-only vars (postgres_*) that this
        # app's own config doesn't consume directly.


settings = Settings()
