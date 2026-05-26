-- ============================================
-- ベクトルデータ生成状況の確認
-- ============================================
-- このスクリプトはベクトルデータの生成状況を確認するためのものです
-- 実際のベクトル生成には scripts/generate-embeddings.py を使用してください

-- vector拡張機能の有効化確認
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        RAISE EXCEPTION 'vector拡張機能が有効になっていません。01-init.sqlを実行してください。';
    END IF;
END $$;

-- ベクトル未設定商品の確認
DO $$
DECLARE
    product_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO product_count
    FROM products
    WHERE embedding IS NULL;
    
    IF product_count > 0 THEN
        RAISE NOTICE 'ベクトルが設定されていない商品が % 件あります。', product_count;
        RAISE NOTICE 'ベクトルを生成するには、scripts/generate-embeddings.py を実行してください。';
    END IF;
END $$;

-- ベクトルが設定されている商品の数を確認
SELECT 
    COUNT(*) AS total_products,
    COUNT(embedding) AS products_with_embedding,
    COUNT(*) - COUNT(embedding) AS products_without_embedding
FROM products;
