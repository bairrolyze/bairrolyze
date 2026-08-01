from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class AmenityCategory(str, Enum):
    transportation = "transportation"
    education = "education"
    healthcare = "healthcare"
    shopping = "shopping"
    safety = "safety"
    religion = "religion"
    recreation = "recreation"


class GeocodeRequest(BaseModel):
    address: str = Field(..., min_length=3, description="Full address string")
    country_code: str = Field(default="PT", max_length=3)


class GeocodeResponse(BaseModel):
    lat: float
    lng: float
    display_name: str
    country: str
    city: Optional[str] = None
    confidence: float = 1.0


class AmenityModel(BaseModel):
    id: str
    name: str
    category: AmenityCategory
    type: str
    lat: float
    lng: float
    distance_meters: Optional[int] = None
    walking_minutes: Optional[int] = None
    driving_minutes: Optional[int] = None
    address: Optional[str] = None
    tags: Optional[Dict[str, Any]] = None


class AmenitiesRequest(BaseModel):
    lat: float
    lng: float
    radius: float = Field(default=2000.0, ge=100, le=10000)


class AmenitiesResponse(BaseModel):
    amenities: List[AmenityModel]
    total: int
    radius: float


class CategoryScore(BaseModel):
    id: str
    label: str
    score: float = Field(ge=0, le=100)
    count: int
    weight: float
    closest: Optional[AmenityModel] = None


class LocationScore(BaseModel):
    overall: float = Field(ge=0, le=100)
    categories: Dict[str, CategoryScore]
    profile: str
    calculated_at: datetime


class ScoreRequest(BaseModel):
    lat: float
    lng: float
    amenities: List[AmenityModel]
    profile: str = "default"


class AiSummaryRequest(BaseModel):
    address: str
    score: LocationScore
    amenities_count: int


class AiSummaryResponse(BaseModel):
    summary: str


class AnalyzeRequest(BaseModel):
    address: str = Field(..., min_length=3)
    country_code: str = Field(default="PT")
    profile: str = Field(default="default")
    radius: float = Field(default=2000.0, ge=100, le=10000)


class AnalyzeResponse(BaseModel):
    id: str
    analyzed_at: datetime
    address: GeocodeResponse
    score: LocationScore
    amenities: List[AmenityModel]
    ai_summary: Optional[str] = None
    profile: str


class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
    code: Optional[str] = None


# ── Job-based analyze pipeline (Phase B) ─────────────────────────────────────
# The 4 real pipeline stages: geocode -> amenities -> score -> ai_summary.
# Strict sequential dependency chain (each needs the previous stage's
# output), so there's no stage-level concurrency here — the value is
# progressive delivery of each stage's result as it completes, via
# GET /analyze/{id}/status (poll) or GET /analyze/{id}/stream (SSE).

JOB_STAGE_NAMES = ["geocode", "amenities", "score", "ai_summary"]


class StageState(BaseModel):
    """Status of a single pipeline stage.

    status: "pending" | "running" | "done" | "error" | "blocked"
    ("blocked" = a prior stage in the chain failed, so this stage was
    never attempted.)
    """

    status: str = "pending"
    result: Optional[Any] = None
    error: Optional[str] = None


class JobStages(BaseModel):
    geocode: StageState = Field(default_factory=StageState)
    amenities: StageState = Field(default_factory=StageState)
    score: StageState = Field(default_factory=StageState)
    ai_summary: StageState = Field(default_factory=StageState)


class JobCreatedResponse(BaseModel):
    """Returned immediately (202 Accepted) by POST /analyze."""

    analysis_id: str
    status: str = "pending"


class JobStatusResponse(BaseModel):
    """Returned by GET /analyze/{id}/status and used as the SSE payload shape."""

    analysis_id: str
    status: str  # "pending" | "running" | "done" | "error"
    partial_failure: bool = False
    stages: JobStages
    final: Optional[AnalyzeResponse] = None
    created_at: str
    updated_at: str
