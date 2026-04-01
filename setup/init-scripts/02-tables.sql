-- ============================================
-- テーブル作成: 商品マスタ
-- ============================================

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    product_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'discontinued', 'out_of_stock')),
    image_url VARCHAR(500),
    weight_kg DECIMAL(8, 2),
    dimensions VARCHAR(100),
    embedding vector(1024),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 在庫テーブル
CREATE TABLE IF NOT EXISTS product_stocks (
    product_id INTEGER PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- updated_atカラムを自動更新する関数
-- レコード更新時にupdated_atを現在時刻に設定する
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_at自動更新トリガー
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_stocks_updated_at
    BEFORE UPDATE ON product_stocks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- embeddingカラム: 商品名と説明をベクトル化した埋め込みベクトル（AI生成）
-- 1024次元はBAAI/bge-m3モデルの出力次元数
COMMENT ON COLUMN products.embedding IS '商品名と説明をベクトル化した埋め込みベクトル（AI生成）。1024次元（BAAI/bge-m3）。';

