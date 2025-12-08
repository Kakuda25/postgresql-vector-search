-- ============================================
-- インデックス作成: パフォーマンス最適化
-- ============================================

-- 商品コード検索の高速化
CREATE INDEX IF NOT EXISTS idx_products_product_code ON products(product_code);
-- ステータスフィルタの高速化
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
-- 価格範囲検索の高速化
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
-- 作成日時ソートの高速化
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);

-- 商品名・説明の部分一致検索を高速化（pg_trgm拡張機能を使用）
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_description_trgm ON products USING gin(description gin_trgm_ops);

-- 在庫数検索の高速化
CREATE INDEX IF NOT EXISTS idx_product_stocks_quantity ON product_stocks(quantity);

-- ベクトル検索用インデックス（HNSW: 高速近似最近傍探索）
-- ベクトルカラムが存在する場合のみ作成（マイグレーション時のエラー回避）
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'embedding'
    ) THEN
        -- HNSWインデックス: 高速だがメモリを多く使用
        -- m = 16: 各ノードの最大接続数（増やすと精度向上、メモリ使用量増加）
        -- ef_construction = 64: 構築時の探索範囲（増やすと精度向上、構築時間増加）
        CREATE INDEX IF NOT EXISTS idx_products_embedding_hnsw 
        ON products USING hnsw (embedding vector_cosine_ops)
        WITH (m = 16, ef_construction = 64);
        
        -- 代替案: IVFFlatインデックス（メモリ効率が良いが、HNSWより遅い）
        -- CREATE INDEX IF NOT EXISTS idx_products_embedding_ivfflat 
        -- ON products USING ivfflat (embedding vector_cosine_ops)
        -- WITH (lists = 100);
    END IF;
END $$;

