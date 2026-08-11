import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from config.settings import settings
from api.routes import geocode, amenities, score, ai_summary, analyze, popular, areas

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("HomeScope API starting up...")
    yield
    logger.info("HomeScope API shutting down...")
    from geocoding.nominatim import nominatim_service
    from services.overpass_service import overpass_service
    from services.routing_service import routing_service
    from services.cache import cache_service
    from services.crime_service import crime_service
    from services.job_store import job_store
    from services.popularity_store import popularity_store
    await nominatim_service.close()
    await overpass_service.close()
    await routing_service.close()
    await cache_service.close()
    await crime_service.close()
    await job_store.close()
    await popularity_store.close()


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="HomeScope – Know your neighborhood before you move.",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "detail": str(exc)},
    )


# Mount routers
app.include_router(geocode.router, prefix="/api/v1", tags=["Geocoding"])
app.include_router(amenities.router, prefix="/api/v1", tags=["Amenities"])
app.include_router(score.router, prefix="/api/v1", tags=["Scoring"])
app.include_router(ai_summary.router, prefix="/api/v1", tags=["AI"])
app.include_router(analyze.router, prefix="/api/v1", tags=["Analysis"])
app.include_router(popular.router, prefix="/api/v1", tags=["Popular"])
app.include_router(areas.router, prefix="/api/v1", tags=["Areas"])


@app.get("/health", tags=["Health"])
async def health():
    return {
        "status": "ok",
        "version": settings.app_version,
        "openai": bool(settings.openai_api_key),
        "openroute": bool(settings.openroute_api_key),
    }


@app.get("/", tags=["Root"])
async def root():
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "docs": "/docs",
    }
