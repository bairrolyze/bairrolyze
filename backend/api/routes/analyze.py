import logging
import uuid

from fastapi import APIRouter, BackgroundTasks, HTTPException
from fastapi.responses import StreamingResponse

from models.schemas import AnalyzeRequest, JobCreatedResponse, JobStatusResponse
from services.analysis_pipeline import run_analysis_pipeline
from services.job_store import job_store
from services.sse import stream_job_events

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/analyze", response_model=JobCreatedResponse, status_code=202)
async def analyze_address(request: AnalyzeRequest, background_tasks: BackgroundTasks):
    """
    Kicks off the 4-stage analyze pipeline (geocode -> amenities -> score ->
    AI summary) as a background task and returns immediately with a job id.

    The pipeline stages have a strict sequential data dependency (amenities
    needs geocode's lat/lng, etc.), so this doesn't block the request on any
    of them — clients track progress via:
      - GET /analyze/{analysis_id}/status  (poll)
      - GET /analyze/{analysis_id}/stream  (SSE, preferred)
    """
    analysis_id = str(uuid.uuid4())
    await job_store.create_job(analysis_id, request.model_dump(mode="json"))
    background_tasks.add_task(run_analysis_pipeline, analysis_id, request)

    logger.info(
        "analyze.job_created",
        extra={"analysis_id": analysis_id, "address": request.address, "profile": request.profile},
    )
    return JobCreatedResponse(analysis_id=analysis_id, status="pending")


@router.get("/analyze/{analysis_id}/status", response_model=JobStatusResponse)
async def get_analysis_status(analysis_id: str):
    job = await job_store.get_job(analysis_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Analysis job not found or expired")
    return job


@router.get("/analyze/{analysis_id}/stream")
async def stream_analysis(analysis_id: str):
    job = await job_store.get_job(analysis_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Analysis job not found or expired")

    return StreamingResponse(
        stream_job_events(analysis_id),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            # Disable proxy buffering (e.g. nginx) so events flush promptly.
            "X-Accel-Buffering": "no",
        },
    )
