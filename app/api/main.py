from __future__ import annotations

import threading
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import psycopg2
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from sentence_transformers import SentenceTransformer

from app.utils.categories import PRODUCT_CATEGORIES, category_label
from app.utils.embedding_jobs import create_job, ensure_schema, get_failures, get_job, recover_stale_jobs, update_job
from app.utils.env_loader import get_db_config
from app.utils.vector_utils import (
    VECTOR_DIMENSION,
    adjust_dimension,
    format_vector_for_pg,
    parse_vector_string,
)

MODEL_NAME = "BAAI/bge-m3"

app = FastAPI(title="PostgreSQL Vector Search UI API", version="0.1.0")

web_dir = Path(__file__).resolve().parent.parent / "web"

NO_CACHE_HEADERS = {
    "Cache-Control": "no-cache, no-store, must-revalidate",
    "Pragma": "no-cache",
}

app.mount("/assets", StaticFiles(directory=str(web_dir)), name="assets")


@app.middleware("http")
async def disable_ui_cache(request: Request, call_next):
    response = await call_next(request)
    if request.url.path == "/" or request.url.path.startswith("/assets/"):
        for key, value in NO_CACHE_HEADERS.items():
            response.headers[key] = value
    return response

_model_cache: SentenceTransformer | None = None
_model_lock = threading.Lock()
_schema_initialized = False
_schema_lock = threading.Lock()


@app.on_event("startup")
def startup_recover_jobs():
    global _schema_initialized
    conn = _get_connection()
    try:
        ensure_schema(conn)
        recover_stale_jobs(conn)
        _schema_initialized = True
    finally:
        conn.close()


def _ensure_schema_once(conn) -> None:
    global _schema_initialized
    if _schema_initialized:
        return
    with _schema_lock:
        if not _schema_initialized:
            ensure_schema(conn)
            _schema_initialized = True


class SimilaritySearchRequest(BaseModel):
    type: str = Field(pattern="^(product|text)$")
    productId: int | None = None
    text: str | None = None
    topK: int = Field(default=10, ge=1, le=50)
    scoreThreshold: float = Field(default=0.0, ge=-1.0, le=1.0)
    category: str | None = None


class EmbeddingJobRequest(BaseModel):
    mode: str = Field(pattern="^(all|missing)$")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _get_connection():
    cfg = get_db_config()
    if not cfg["password"]:
        raise HTTPException(status_code=500, detail="POSTGRES_PASSWORD が未設定です")
    return psycopg2.connect(
        host=cfg["host"],
        port=cfg["port"],
        database=cfg["database"],
        user=cfg["user"],
        password=cfg["password"],
    )


def _get_model() -> SentenceTransformer:
    global _model_cache
    if _model_cache is None:
        with _model_lock:
            if _model_cache is None:
                _model_cache = SentenceTransformer(MODEL_NAME)
    return _model_cache


def _search_with_vector(
    query_embedding: np.ndarray,
    top_k: int,
    score_threshold: float,
    exclude_product_id: int | None = None,
    category: str | None = None,
):
    vec_literal = format_vector_for_pg(query_embedding)
    vec_type = f"vector({VECTOR_DIMENSION})"

    conditions = ["embedding IS NOT NULL"]
    params: list[Any] = [vec_literal]

    if exclude_product_id is not None:
        conditions.append("id != %s")
        params.append(exclude_product_id)

    if category:
        conditions.append("category = %s")
        params.append(category)

    conditions.append(f"1 - (embedding <=> %s::{vec_type}) >= %s")
    params.extend([vec_literal, score_threshold])

    where_sql = " AND ".join(conditions)
    params.extend([vec_literal, top_k])

    conn = _get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            f"""
            SELECT id, product_code, name, description, price, category,
                   1 - (embedding <=> %s::{vec_type}) AS similarity
            FROM products
            WHERE {where_sql}
            ORDER BY embedding <=> %s::{vec_type}
            LIMIT %s
            """,
            params,
        )
        rows = cur.fetchall()
    finally:
        conn.close()

    return [
        {
            "productId": pid,
            "productCode": code,
            "name": name,
            "description": description or "",
            "price": float(price),
            "category": cat,
            "categoryLabel": category_label(cat),
            "score": round(float(similarity), 6),
            "rank": rank,
        }
        for rank, (pid, code, name, description, price, cat, similarity) in enumerate(rows, start=1)
    ]


def _run_embedding_job(job_id: str, mode: str):
    conn = _get_connection()
    try:
        _ensure_schema_once(conn)
        update_job(conn, job_id, status="running", started_at=_now_iso(), clear_error=True)

        model = _get_model()
        cur = conn.cursor()
        if mode == "missing":
            cur.execute(
                """
                SELECT id, product_code, name, description
                FROM products
                WHERE embedding IS NULL
                ORDER BY id
                """
            )
        else:
            cur.execute(
                """
                SELECT id, product_code, name, description
                FROM products
                ORDER BY id
                """
            )
        targets = cur.fetchall()
        update_job(conn, job_id, total=len(targets))

        success_count = 0
        failures: list[dict[str, Any]] = []

        for product_id, product_code, name, description in targets:
            text = f"{name} {description or ''}".strip()
            try:
                embedding = model.encode(text, normalize_embeddings=True, convert_to_numpy=True)
                embedding = adjust_dimension(embedding)
                embedding_str = "[" + ",".join(map(str, embedding.tolist())) + "]"
                cur.execute(
                    f"""
                    UPDATE products
                    SET embedding = %s::vector({VECTOR_DIMENSION})
                    WHERE id = %s
                    """,
                    (embedding_str, product_id),
                )
                success_count += 1
            except Exception as exc:  # noqa: BLE001
                failures.append({"productId": product_id, "productCode": product_code, "reason": str(exc)})

            update_job(
                conn,
                job_id,
                success_count=success_count,
                fail_count=len(failures),
                progress=(success_count + len(failures)) / max(len(targets), 1),
                failures=failures,
            )

        conn.commit()
        update_job(conn, job_id, status="done", finished_at=_now_iso(), clear_error=True)
    except Exception as exc:  # noqa: BLE001
        conn.rollback()
        update_job(conn, job_id, status="error", error=str(exc), finished_at=_now_iso())
    finally:
        conn.close()


@app.get("/")
def root():
    return FileResponse(str(web_dir / "index.html"), headers=NO_CACHE_HEADERS)


@app.get("/api/meta/categories")
def meta_categories():
    return {"items": PRODUCT_CATEGORIES}


@app.get("/api/system/health")
def system_health():
    try:
        conn = _get_connection()
        cur = conn.cursor()
        cur.execute("SELECT extname FROM pg_extension WHERE extname = 'vector'")
        has_vector = cur.fetchone() is not None
        conn.close()
        return {"api": "ok", "db": "ok", "pgvector": "ok" if has_vector else "ng", "checkedAt": _now_iso()}
    except Exception:  # noqa: BLE001
        return {"api": "ok", "db": "ng", "pgvector": "ng", "checkedAt": _now_iso()}


@app.get("/api/dashboard/summary")
def dashboard_summary():
    conn = _get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT COUNT(*) AS total,
                   COUNT(embedding) AS embedded
            FROM products
            """
        )
        total, embedded = cur.fetchone()
    finally:
        conn.close()
    return {"totalProducts": total, "embeddedProducts": embedded, "missingEmbeddings": total - embedded}


def _serialize_product(row: tuple[Any, ...]) -> dict[str, Any]:
    return {
        "id": row[0],
        "productCode": row[1],
        "name": row[2],
        "category": row[3],
        "categoryLabel": category_label(row[3]),
        "price": float(row[4]),
        "embeddingStatus": "embedded" if row[5] else "missing",
        "description": row[6] or "",
        "imageUrl": row[7] or None,
    }


@app.get("/api/products")
def get_products(
    q: str | None = None,
    embeddingStatus: str | None = None,
    category: str | None = None,
    limit: int = 100,
):
    conn = _get_connection()
    try:
        cur = conn.cursor()
        params: list[Any] = []
        filters = []

        if q:
            filters.append("(name ILIKE %s OR product_code ILIKE %s)")
            params.extend([f"%{q}%", f"%{q}%"])
        if embeddingStatus == "embedded":
            filters.append("embedding IS NOT NULL")
        elif embeddingStatus == "missing":
            filters.append("embedding IS NULL")
        if category:
            filters.append("category = %s")
            params.append(category)

        params.append(limit)
        where_sql = f" WHERE {' AND '.join(filters)}" if filters else ""

        cur.execute(
            "SELECT id, product_code, name, category, price, (embedding IS NOT NULL) AS embedded,"
            f" description, image_url FROM products{where_sql} ORDER BY id LIMIT %s",
            tuple(params),
        )
        rows = cur.fetchall()
    finally:
        conn.close()

    return {"items": [_serialize_product(row) for row in rows]}


@app.get("/api/products/{product_id}")
def get_product(product_id: int):
    conn = _get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, product_code, name, category, price, (embedding IS NOT NULL) AS embedded,
                   description, image_url
            FROM products
            WHERE id = %s
            """,
            (product_id,),
        )
        row = cur.fetchone()
    finally:
        conn.close()

    if not row:
        raise HTTPException(status_code=404, detail="商品が見つかりません")
    return _serialize_product(row)


@app.post("/api/similarity/search")
def similarity_search(payload: SimilaritySearchRequest):
    if payload.category and payload.category not in {c["value"] for c in PRODUCT_CATEGORIES}:
        raise HTTPException(status_code=400, detail="無効な category です")

    model = _get_model()
    if payload.type == "product":
        if payload.productId is None:
            raise HTTPException(status_code=400, detail="productId が必要です")
        conn = _get_connection()
        try:
            cur = conn.cursor()
            cur.execute("SELECT embedding FROM products WHERE id = %s AND embedding IS NOT NULL", (payload.productId,))
            row = cur.fetchone()
        finally:
            conn.close()
        if not row:
            raise HTTPException(status_code=404, detail="対象商品の embedding が見つかりません")
        query_embedding = parse_vector_string(row[0])
    else:
        if not payload.text:
            raise HTTPException(status_code=400, detail="text が必要です")
        query_embedding = model.encode(payload.text, normalize_embeddings=True, convert_to_numpy=True)
        query_embedding = adjust_dimension(query_embedding)

    exclude_id = payload.productId if payload.type == "product" else None
    items = _search_with_vector(
        query_embedding,
        payload.topK,
        payload.scoreThreshold,
        exclude_product_id=exclude_id,
        category=payload.category,
    )
    return {"query": payload.model_dump(), "items": items}


@app.post("/api/embeddings/jobs")
def create_embedding_job(payload: EmbeddingJobRequest):
    job_id = str(uuid.uuid4())
    conn = _get_connection()
    try:
        _ensure_schema_once(conn)
        create_job(conn, job_id, payload.mode)
    finally:
        conn.close()

    thread = threading.Thread(target=_run_embedding_job, args=(job_id, payload.mode), daemon=True)
    thread.start()
    return {"jobId": job_id, "status": "queued"}


@app.get("/api/embeddings/jobs/{job_id}")
def get_embedding_job(job_id: str):
    conn = _get_connection()
    try:
        _ensure_schema_once(conn)
        job = get_job(conn, job_id)
    finally:
        conn.close()
    if not job:
        raise HTTPException(status_code=404, detail="job が見つかりません")
    return job


@app.get("/api/embeddings/failures")
def get_embedding_failures(jobId: str):
    conn = _get_connection()
    try:
        _ensure_schema_once(conn)
        job = get_job(conn, jobId)
        if not job:
            raise HTTPException(status_code=404, detail="job が見つかりません")
        items = get_failures(conn, jobId)
    finally:
        conn.close()
    return {"items": items}
