-- ============================================
-- マイグレーション: 商品カテゴリ列（既存 DB 用）
-- ============================================

ALTER TABLE products ADD COLUMN IF NOT EXISTS category VARCHAR(50);

UPDATE products
SET category = CASE split_part(product_code, '-', 1)
    WHEN 'ELEC' THEN 'electronics'
    WHEN 'FASH' THEN 'fashion'
    WHEN 'FOOD' THEN 'food'
    WHEN 'HOME' THEN 'home'
    WHEN 'BEAU' THEN 'beauty'
    WHEN 'SPOR' THEN 'sports'
    WHEN 'BOOK' THEN 'books'
    WHEN 'TOYS' THEN 'toys'
    ELSE 'other'
END
WHERE category IS NULL;

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

COMMENT ON COLUMN products.category IS '商品カテゴリ（通販カテゴリ: electronics, fashion 等）。';
