-- ============================================
-- ベクトル検索対応: マイグレーション
-- ============================================
-- 既存データベースにベクトル検索機能を追加するためのマイグレーション
-- 初回起動時（新規DB作成時）には不要（02-tables.sqlにembeddingカラムが含まれている）

-- ベクトル拡張機能の有効化
CREATE EXTENSION IF NOT EXISTS "vector";

-- productsテーブルにベクトルカラムを追加
-- 1536次元はOpenAI text-embedding-ada-002の次元数に合わせている
-- 他のモデルを使用する場合は次元数を変更する必要がある
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- embeddingカラムの説明
COMMENT ON COLUMN products.embedding IS '商品名と説明をベクトル化した埋め込みベクトル（AI生成）';

