"""Redis-backed job store for the background analyze pipeline.

Each job is a single JSON blob at key `job:{analysis_id}` with a TTL
(settings.job_ttl_seconds — jobs are transient, distinct from the data-cache
TTLs used for geocode/amenity result caching elsewhere). Every write is a
full read-modify-write of the record, so stage updates are idempotent
(overwrite, not append) — safe to retry.

This module only talks to Redis; it knows nothing about geocoding,
amenities, scoring, or AI summaries. That orchestration lives in
`services/analysis_pipeline.py`.
"""

import json
import logging
from datetime import datetime, timezone
from typing import Any, Optional

import redis.asyncio as redis

from config.settings import settings

logger = logging.getLogger(__name__)

JOB_KEY_PREFIX = "job:"

# The 4 real pipeline stages, in dependency order.
STAGE_NAMES = ["geocode", "amenities", "score", "ai_summary"]

# Job-level statuses.
STATUS_PENDING = "pending"
STATUS_RUNNING = "running"
STATUS_DONE = "done"
STATUS_ERROR = "error"

# Per-stage statuses.
STAGE_PENDING = "pending"
STAGE_RUNNING = "running"
STAGE_DONE = "done"
STAGE_ERROR = "error"
STAGE_BLOCKED = "blocked"


def _job_key(analysis_id: str) -> str:
    return f"{JOB_KEY_PREFIX}{analysis_id}"


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _empty_stage() -> dict:
    return {"status": STAGE_PENDING, "result": None, "error": None}


class JobStore:
    def __init__(self, redis_url: Optional[str] = None, ttl_seconds: Optional[int] = None):
        self._redis_url = redis_url or settings.redis_url
        self._ttl_seconds = ttl_seconds if ttl_seconds is not None else settings.job_ttl_seconds
        self._client: Optional["redis.Redis"] = None

    @property
    def client(self) -> "redis.Redis":
        if self._client is None:
            self._client = redis.from_url(self._redis_url, decode_responses=True)
        return self._client

    async def create_job(self, analysis_id: str, request: dict) -> dict:
        now = _now_iso()
        job = {
            "analysis_id": analysis_id,
            "status": STATUS_PENDING,
            "partial_failure": False,
            "request": request,
            "stages": {name: _empty_stage() for name in STAGE_NAMES},
            "final": None,
            "created_at": now,
            "updated_at": now,
        }
        await self._write(analysis_id, job)
        return job

    async def get_job(self, analysis_id: str) -> Optional[dict]:
        raw = await self.client.get(_job_key(analysis_id))
        if raw is None:
            return None
        return json.loads(raw)

    async def set_job_status(
        self,
        analysis_id: str,
        status: str,
        partial_failure: Optional[bool] = None,
        final: Optional[dict] = None,
    ) -> Optional[dict]:
        job = await self.get_job(analysis_id)
        if job is None:
            logger.warning(
                "job_store.set_job_status: job not found",
                extra={"analysis_id": analysis_id, "status": status},
            )
            return None
        job["status"] = status
        if partial_failure is not None:
            job["partial_failure"] = partial_failure
        if final is not None:
            job["final"] = final
        await self._write(analysis_id, job)
        return job

    async def update_stage(
        self,
        analysis_id: str,
        stage: str,
        status: str,
        result: Any = None,
        error: Optional[str] = None,
    ) -> Optional[dict]:
        """Idempotent overwrite of a single stage's state. Safe to call
        repeatedly for the same stage (e.g. 'running' then 'done') — always
        replaces, never appends.
        """
        job = await self.get_job(analysis_id)
        if job is None:
            logger.warning(
                "job_store.update_stage: job not found",
                extra={"analysis_id": analysis_id, "stage": stage},
            )
            return None
        job["stages"][stage] = {"status": status, "result": result, "error": error}
        await self._write(analysis_id, job)
        return job

    async def _write(self, analysis_id: str, job: dict) -> None:
        job["updated_at"] = _now_iso()
        await self.client.set(
            _job_key(analysis_id),
            json.dumps(job, default=str),
            ex=self._ttl_seconds,
        )

    async def close(self) -> None:
        if self._client is not None:
            await self._client.close()
            self._client = None


job_store = JobStore()
