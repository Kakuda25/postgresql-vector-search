-- ============================================
-- Embedding ジョブ永続化テーブル
-- ============================================

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
);

CREATE INDEX IF NOT EXISTS idx_embedding_jobs_status ON embedding_jobs(status);
CREATE INDEX IF NOT EXISTS idx_embedding_jobs_created_at ON embedding_jobs(created_at DESC);
