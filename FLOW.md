# プロジェクトフロー

仕様 SSOT: `.cursor/order/projectFeatures.mdc`

## 全体フロー

```
【セットアップ】
  1. .env 作成（env.template から）
  2. docker-compose up -d
  3. init-scripts 自動実行（拡張・テーブル・インデックス・シード 42 件）
  4. setup-venv → requirements インストール

【ベクトル生成】
  1. venv 有効化 + POSTGRES_PASSWORD 設定
  2. generate-embeddings.py または Web UI「Embedding 運用」
  3. BAAI/bge-m3 で name + description を vector(1024) に保存

【類似検索】
  1. CLI: search-similar-products.py "クエリ"
  2. Web UI: #/catalog/search または #/admin/search → POST /api/similarity/search
  3. NumPy 内積でコサイン類似度（正規化済みベクトル）

【Web UI】
  1. run-web-ui.py → http://localhost:8000
  2. #/catalog（ストア）| #/admin/dashboard | #/admin/products | #/admin/search | #/admin/operations
```

## セットアップフロー

```
env.template → .env
    ↓
docker-compose up -d
    ↓
01-init.sql      → pgvector, pg_trgm
02-tables.sql    → products, product_stocks (embedding vector(1024))
03-indexes.sql   → B-tree, GIN, HNSW
04-seed-data.sql → 42 商品 + 在庫（embedding = NULL）
    ↓
setup-venv.ps1 / .sh
    ↓
generate-embeddings.py（embedding IS NULL のみ更新）
```

## ベクトル生成フロー

```
python app/scripts/generate-embeddings.py [--model BAAI/bge-m3]
    │
    ├─ DB 接続（create_connection）
    ├─ SELECT ... WHERE embedding IS NULL
    ├─ SentenceTransformer('BAAI/bge-m3')  ※初回は Hugging Face から DL
    ├─ テキスト: "{name} {description}"
    ├─ encode(normalize_embeddings=True) → 1024 次元
    └─ UPDATE products SET embedding = %s::vector(1024)
```

**Web UI 経由（API ジョブ）**

```
POST /api/embeddings/jobs { mode: "missing" | "all" }
    → バックグラウンド Thread
    → GET /api/embeddings/jobs/{jobId} で進捗ポーリング
```

## 類似検索フロー

**CLI（テキスト）**

```
  python app/scripts/search-similar-products.py "ワイヤレスイヤホン"
    ├─ クエリを bge-m3 で encode
    ├─ 全商品 embedding を取得
    ├─ ensure_same_dimension + 内積
    └─ 類似度降順で表示
```

**CLI（商品比較）**

```
python app/scripts/search-similar-products.py --compare-products --product-id 1
    └─ 基準商品を除外して類似商品を返す
```

**Web UI / API**

```
POST /api/similarity/search
  type=text   → クエリを encode
  type=product → DB の embedding を使用
    └─ _search_with_vector（全件 Python スキャン、pgvector SQL 未使用）
```

## データフロー

```
04-seed-data.sql → products (embedding=NULL)
        ↓
generate-embeddings / API job → UPDATE embedding vector(1024)
        ↓
search CLI / API → SELECT embedding → 類似度計算 → 結果表示
```

## 日常的な使用

| 操作 | コマンド |
|------|----------|
| 新規商品の embedding | `python app/scripts/generate-embeddings.py` |
| テキスト検索 | `python app/scripts/search-similar-products.py "クエリ"` |
| Web UI | `python app/scripts/run-web-ui.py` |
| 全件再生成（API） | Web UI Operations → mode `all` |
| 全件再生成（CLI） | `UPDATE products SET embedding = NULL` の後 generate |

## トラブルシューティング

| 問題 | 確認 |
|------|------|
| DB 接続失敗 | `docker ps`, `.env` の `POSTGRES_PASSWORD`, `align-postgres-password-with-env.ps1` |
| embedding なし | `generate-embeddings.py` 実行、または Web UI でジョブ開始 |
| 検索精度が低い | モデルは bge-m3 か、embedding が全商品に設定されているか |
| 次元不一致 | スキーマは `vector(1024)`。モデル出力と一致させる |

## クイックリファレンス

```powershell
.\venv\Scripts\Activate.ps1
python app/scripts/generate-embeddings.py
  python app/scripts/search-similar-products.py "ワイヤレスイヤホン"
python app/scripts/run-web-ui.py
```
