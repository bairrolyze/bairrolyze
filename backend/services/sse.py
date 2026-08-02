"""SSE event framing for GET /analyze/{id}/stream.

Polls the Redis job record (JobStore) at a short interval and emits one SSE
event per observed change: a `job_status` event whenever the job-level
status changes, and a `stage` event whenever a stage's status changes.
Emits a final `complete` event and closes once the job reaches "done" or
"error". A max-duration safety cutoff prevents a stuck job from holding the
HTTP connection open forever.
"""

import asyncio
import json
import logging
import time
from typing import AsyncGenerator

from config.settings import settings
from services.job_store import STAGE_NAMES, job_store

logger = logging.getLogger(__name__)


def _format_event(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data, default=str)}\n\n"


async def stream_job_events(
    analysis_id: str,
    poll_interval_seconds: float = None,
    max_stream_seconds: int = None,
) -> AsyncGenerator[str, None]:
    poll_interval_seconds = poll_interval_seconds or settings.job_stream_poll_seconds
    max_stream_seconds = max_stream_seconds or settings.job_stream_max_seconds

    start = time.monotonic()
    last_stage_statuses = {name: None for name in STAGE_NAMES}
    last_job_status = None

    while True:
        if time.monotonic() - start > max_stream_seconds:
            logger.warning("sse.stream_timeout", extra={"analysis_id": analysis_id})
            yield _format_event(
                "timeout",
                {"analysis_id": analysis_id, "message": "stream exceeded max duration, stop polling and use /status"},
            )
            return

        job = await job_store.get_job(analysis_id)
        if job is None:
            yield _format_event("error", {"analysis_id": analysis_id, "message": "job not found or expired"})
            return

        if job["status"] != last_job_status:
            last_job_status = job["status"]
            yield _format_event(
                "job_status",
                {
                    "analysis_id": analysis_id,
                    "status": job["status"],
                    "progress": job.get("progress", 0),
                    "partial_failure": job.get("partial_failure", False),
                },
            )

        for stage_name in STAGE_NAMES:
            stage = job["stages"].get(stage_name) or {}
            stage_status = stage.get("status")
            if stage_status != last_stage_statuses[stage_name]:
                last_stage_statuses[stage_name] = stage_status
                yield _format_event(
                    "stage",
                    {
                        "analysis_id": analysis_id,
                        # `type` mirrors `stage` (e.g. "address_found",
                        # "amenities_ready") — both carry the same value;
                        # `type` matches the event-name-as-payload-field
                        # shape client integrations commonly expect.
                        "type": stage_name,
                        "stage": stage_name,
                        "status": stage_status,
                        "progress": job.get("progress", 0),
                        "result": stage.get("result"),
                        "error": stage.get("error"),
                    },
                )

        if job["status"] in ("done", "error"):
            yield _format_event(
                "complete",
                {
                    "analysis_id": analysis_id,
                    "type": "completed",
                    "status": job["status"],
                    "progress": job.get("progress", 0),
                    "partial_failure": job.get("partial_failure", False),
                    "final": job.get("final"),
                },
            )
            return

        await asyncio.sleep(poll_interval_seconds)
