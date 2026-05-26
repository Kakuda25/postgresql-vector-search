"""Embedding ジョブの PostgreSQL 永続化"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


CREATE_JOBS_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS embedding_jobs (
    job_id UUID PRIMARY KEY,
    mode VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    progress DOUBLE PRECISION NOT NULL DEFAULT 0,
    total INTEGER NOT NULL DEFAULT 0,
    success_count INTEGER NOT NULL DEFAULT 0,
    fail_count INTEGER NOT NULL DEFAULT 0,
    failures JSONB NOT NULL DEFAULT '[]'::jsonb,
    error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ
)
"""

RECOVER_STALE_JOBS_SQL = """
UPDATE embedding_jobs
SET status = 'error',
    error = 'server restarted',
    finished_at = COALESCE(finished_at, CURRENT_TIMESTAMP)
WHERE status IN ('queued', 'running')
"""


def ensure_schema(conn) -> None:
    cur = conn.cursor()
    cur.execute(CREATE_JOBS_TABLE_SQL)
    conn.commit()


def recover_stale_jobs(conn) -> None:
    cur = conn.cursor()
    cur.execute(RECOVER_STALE_JOBS_SQL)
    conn.commit()


def _row_to_job(row: tuple) -> dict[str, Any]:
    (
        job_id,
        mode,
        status,
        progress,
        total,
        success_count,
        fail_count,
        failures,
        error,
        created_at,
        started_at,
        finished_at,
    ) = row
    return {
        "jobId": str(job_id),
        "mode": mode,
        "status": status,
        "progress": float(progress),
        "total": int(total),
        "successCount": int(success_count),
        "failCount": int(fail_count),
        "failures": failures if isinstance(failures, list) else json.loads(failures or "[]"),
        "error": error,
        "createdAt": created_at.isoformat() if created_at else None,
        "startedAt": started_at.isoformat() if started_at else None,
        "finishedAt": finished_at.isoformat() if finished_at else None,
    }


def create_job(conn, job_id: str, mode: str) -> dict[str, Any]:
    cur = conn.cursor()
    created_at = _now_iso()
    cur.execute(
        """
        INSERT INTO embedding_jobs (job_id, mode, status, created_at)
        VALUES (%s::uuid, %s, 'queued', %s::timestamptz)
        """,
        (job_id, mode, created_at),
    )
    conn.commit()
    return {
        "jobId": job_id,
        "mode": mode,
        "status": "queued",
        "progress": 0.0,
        "total": 0,
        "successCount": 0,
        "failCount": 0,
        "failures": [],
        "error": None,
        "createdAt": created_at,
        "startedAt": None,
        "finishedAt": None,
    }


def update_job(
    conn,
    job_id: str,
    *,
    status: str | None = None,
    progress: float | None = None,
    total: int | None = None,
    success_count: int | None = None,
    fail_count: int | None = None,
    failures: list[dict[str, Any]] | None = None,
    error: str | None = None,
    clear_error: bool = False,
    started_at: str | None = None,
    finished_at: str | None = None,
) -> None:
    fields: list[str] = []
    params: list[Any] = []

    mapping = {
        "status": status,
        "progress": progress,
        "total": total,
        "success_count": success_count,
        "fail_count": fail_count,
    }
    for column, value in mapping.items():
        if value is not None:
            fields.append(f"{column} = %s")
            params.append(value)

    if clear_error:
        fields.append("error = NULL")
    elif error is not None:
        fields.append("error = %s")
        params.append(error)

    if failures is not None:
        fields.append("failures = %s::jsonb")
        params.append(json.dumps(failures, ensure_ascii=False))

    if started_at is not None:
        fields.append("started_at = %s::timestamptz")
        params.append(started_at)

    if finished_at is not None:
        fields.append("finished_at = %s::timestamptz")
        params.append(finished_at)

    if not fields:
        return

    params.append(job_id)
    cur = conn.cursor()
    cur.execute(
        f"UPDATE embedding_jobs SET {', '.join(fields)} WHERE job_id = %s::uuid",
        params,
    )
    conn.commit()


def get_job(conn, job_id: str) -> dict[str, Any] | None:
    cur = conn.cursor()
    cur.execute(
        """
        SELECT job_id, mode, status, progress, total, success_count, fail_count,
               failures, error, created_at, started_at, finished_at
        FROM embedding_jobs
        WHERE job_id = %s::uuid
        """,
        (job_id,),
    )
    row = cur.fetchone()
    return _row_to_job(row) if row else None


def get_failures(conn, job_id: str) -> list[dict[str, Any]]:
    job = get_job(conn, job_id)
    return job.get("failures", []) if job else []
