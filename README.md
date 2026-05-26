# ベクトル検索デモ（通販商品カタログ）

通販サイト風の商品カタログを使った、PostgreSQL + pgvector ベクトル検索サンプルです。

## 📋 目次

- [機能](#機能)
- [プロジェクト構造](#プロジェクト構造)
- [クイックスタート](#クイックスタート)
- [セットアップ](#セットアップ)
- [使用方法](#使用方法)
  - [基本的な操作](#基本的な操作)
  - [ベクトル検索のセットアップ](#ベクトル検索のセットアップ)
  - [データベースのバックアップとリストア](#データベースのバックアップとリストア)
  - [初期化スクリプト](#初期化スクリプト)
- [デプロイ](#デプロイ)
- [データベーススキーマ](#データベーススキーマ)
- [トラブルシューティング](#トラブルシューティング)

## ✨ 機能

- ✅ PostgreSQL 16 with pgvector - AIベクトル検索対応
- ✅ データの永続化（ボリューム）
- ✅ 初期化スクリプト対応
- ✅ pgAdmin 4（オプション）
- ✅ リソース制限設定
- ✅ ログローテーション
- ✅ セキュアな環境変数管理
- ✅ ベクトル検索（AI埋め込みベクトルによる類似度検索）
- ✅ Web UI（ダッシュボード / 商品 / 類似検索 / Embedding 運用）
- ✅ FastAPI REST API

## 📁 プロジェクト構造

```
vector-search/
├── docker-compose.yml
├── env.template
├── requirements.txt
├── setup/                      # 環境構築用
│   ├── init-scripts/           # DB 初期化 SQL
│   ├── scripts/                # venv セットアップ等
│   └── examples/               # e5 参考サンプル（本番パス外）
└── app/                        # アプリケーション
    ├── api/main.py             # FastAPI
    ├── scripts/                # CLI + run-web-ui.py
    ├── utils/                  # DB / env / ベクトル
    └── web/                    # Web UI
```

詳細は [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) を参照してください。

## 🚀 クイックスタート

**最短でベクトル検索を開始する方法:**

```powershell
# 1. 環境変数ファイルの作成
cp env.template .env
# .envファイルを編集してパスワードを設定

# 2. Docker Composeでデータベースを起動
docker-compose up -d

# 3. 仮想環境のセットアップ（初回のみ）
.\setup\scripts\setup-venv.ps1

# 4. 仮想環境を有効化
.\venv\Scripts\Activate.ps1

# 5. ベクトルを生成
python app/scripts/generate-embeddings.py

# 6. 類似商品を検索
python app/scripts/search-similar-products.py "ワイヤレスイヤホン"

# 7. Web UIを起動
$env:POSTGRES_PASSWORD = "your_password"
python app/scripts/run-web-ui.py
# ブラウザで http://localhost:8000 を開く
```

## 🚀 セットアップ

### 1. 環境変数ファイルの作成

```bash
cp env.template .env
```

`.env`ファイルを編集して、パスワードなどの機密情報を設定してください。

```env
POSTGRES_DB=shopDB
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_PORT=5432
```

### 2. Docker Composeで起動

```bash
docker-compose up -d
```

### 3. 動作確認

```bash
# データベースに直接接続
docker exec -it postgres_db psql -U postgres -d shopDB
```

### 4. Python環境のセットアップ（ベクトル生成用）

**Windows PowerShell:**

```powershell
# 仮想環境のセットアップ（初回のみ）
.\setup\scripts\setup-venv.ps1

# 仮想環境を有効化（毎回実行）
.\venv\Scripts\Activate.ps1

# 環境変数を設定
$env:POSTGRES_PASSWORD = "your_password"

# または、.envファイルから読み込む
Get-Content .env | ForEach-Object {
    if ($_ -match "^POSTGRES_PASSWORD=(.+)$") {
        $env:POSTGRES_PASSWORD = $matches[1]
    }
}
```

**Linux/Mac:**

```bash
# 仮想環境のセットアップ（初回のみ）
bash setup/scripts/setup-venv.sh

# 仮想環境を有効化（毎回実行）
source venv/bin/activate

# 環境変数を設定
export POSTGRES_PASSWORD="your_password"

# または、.envファイルから読み込む
export $(grep -v '^#' .env | xargs)
```

**注意**: 実行ポリシーのエラーが出る場合（Windows PowerShell）:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 5. Web UI/APIの起動

Web管理画面（ダッシュボード/商品管理/類似検索/Embedding運用）を利用する場合は、以下を実行してください。

**Windows PowerShell:**

```powershell
# 仮想環境を有効化
.\venv\Scripts\Activate.ps1

# DBパスワードを環境変数に設定（.envを使う場合は読み込みでも可）
$env:POSTGRES_PASSWORD = "your_password"

# Web UIサーバーを起動
python app/scripts/run-web-ui.py

# アクセス先
# http://localhost:8000
# 画面ルート例:
#   http://localhost:8000/#/catalog          … Vector Search Store（カタログ）
#   http://localhost:8000/#/admin/dashboard  … 管理ダッシュボード
#   http://localhost:8000/#/admin/products   … 商品管理
#   http://localhost:8000/#/admin/search     … 類似検索（検証）
#   http://localhost:8000/#/admin/operations … Embedding 運用
```

**Linux/Mac:**

```bash
# 仮想環境を有効化
source venv/bin/activate

# DBパスワードを環境変数に設定
export POSTGRES_PASSWORD="your_password"

# Web UIサーバーを起動
python app/scripts/run-web-ui.py

# アクセス先
# http://localhost:8000
```

**ベクトル検索機能の確認:**

```sql
-- 1. 拡張機能の確認
SELECT * FROM pg_extension WHERE extname IN ('vector', 'pg_trgm');

-- 2. productsテーブルの構造確認（embeddingカラムが存在することを確認）
\d products

-- 3. サンプルデータの確認
SELECT id, product_code, name, price FROM products LIMIT 5;

-- 4. ベクトルカラムの存在確認
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' AND column_name = 'embedding';

-- 5. ベクトル検索用インデックスの確認
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'products' AND indexname LIKE '%embedding%';
```

**期待される結果:**
- `vector`拡張機能が有効になっている
- `products`テーブルに`embedding vector(1024)`カラムが存在する
- ベクトル検索用のインデックス（`idx_products_embedding_hnsw`）が作成されている
- サンプルデータ（41件の通販商品、8カテゴリ）が登録されている

## 📖 使用方法

### 基本的な操作

```bash
# コンテナの起動
docker-compose up -d

# コンテナの停止
docker-compose stop

# コンテナの停止と削除（データは保持）
docker-compose down

# コンテナの停止と削除（データも削除）
docker-compose down -v

# ログの確認
docker-compose logs -f postgres
```

### データベースのバックアップとリストア

#### バックアップ（手動）

**SQL形式（推奨）:**
```powershell
# .envファイルから環境変数を読み込む（PowerShell）
$env:PGPASSWORD = (Get-Content .env | Select-String "POSTGRES_PASSWORD" | ForEach-Object { $_.Line.Split('=')[1] })
$dbName = (Get-Content .env | Select-String "POSTGRES_DB" | ForEach-Object { $_.Line.Split('=')[1] })
if (-not $dbName) { $dbName = "shopDB" }
$user = (Get-Content .env | Select-String "POSTGRES_USER" | ForEach-Object { $_.Line.Split('=')[1] }) -replace "postgres", "postgres"
if (-not $user) { $user = "postgres" }

# バックアップ実行
docker exec -e PGPASSWORD=$env:PGPASSWORD postgres_db pg_dump -U $user -d $dbName --clean --if-exists --create > backup_$(Get-Date -Format "yyyyMMdd_HHmmss").sql
```

**カスタム形式（圧縮）:**
```powershell
# バックアップ実行
docker exec -e PGPASSWORD=$env:PGPASSWORD postgres_db pg_dump -U $user -d $dbName --format=custom --compress=9 --file=/tmp/backup.dump

# コンテナからホストにコピー
docker cp postgres_db:/tmp/backup.dump backup_$(Get-Date -Format "yyyyMMdd_HHmmss").dump

# コンテナ内の一時ファイルを削除
docker exec postgres_db rm -f /tmp/backup.dump
```

#### リストア（手動）

**⚠️ 警告: リストア操作は既存のデータベースを上書きします**

**SQL形式のリストア:**
```powershell
# .envファイルから環境変数を読み込む
$env:PGPASSWORD = (Get-Content .env | Select-String "POSTGRES_PASSWORD" | ForEach-Object { $_.Line.Split('=')[1] })
$user = (Get-Content .env | Select-String "POSTGRES_USER" | ForEach-Object { $_.Line.Split('=')[1] })
if (-not $user) { $user = "postgres" }

# バックアップファイルを指定（例: backup_20241209_120000.sql）
$backupFile = "backup_20241209_120000.sql"

# リストア実行
Get-Content $backupFile | docker exec -i -e PGPASSWORD=$env:PGPASSWORD postgres_db psql -U $user -d postgres
```

**圧縮SQL形式（.sql.gz）のリストア:**
```powershell
# バックアップファイルを指定（例: backup_20241209_120000.sql.gz）
$backupFile = "backup_20241209_120000.sql.gz"

# 解凍してリストア（gzipが必要な場合、WSLやGit Bashを使用）
# WSLを使用する場合:
wsl gunzip -c $backupFile | docker exec -i -e PGPASSWORD=$env:PGPASSWORD postgres_db psql -U $user -d postgres

# または、事前に解凍してから:
# gunzip $backupFile  # WSL/Git Bashで実行
# その後、上記のSQL形式のリストア手順を実行
```

**カスタム形式（.dump）のリストア:**
```powershell
# バックアップファイルを指定（例: backup_20241209_120000.dump）
$backupFile = "backup_20241209_120000.dump"

# コンテナにバックアップファイルをコピー
docker cp $backupFile postgres_db:/tmp/restore.dump

# リストア実行
docker exec -e PGPASSWORD=$env:PGPASSWORD postgres_db pg_restore -U $user --clean --if-exists --create --dbname=postgres /tmp/restore.dump

# または、既存のデータベースに直接リストアする場合:
docker exec -e PGPASSWORD=$env:PGPASSWORD postgres_db pg_restore -U $user --clean --if-exists --dbname=shopDB /tmp/restore.dump

# 一時ファイルを削除
docker exec postgres_db rm -f /tmp/restore.dump
```

**簡易版（環境変数が.envに正しく設定されている場合）:**
```powershell
# 1. コンテナが起動していることを確認
docker ps | Select-String "postgres_db"

# 2. バックアップファイルのパスを指定
$backupFile = "C:\path\to\your\backup.sql"  # 実際のパスに置き換え

# 3. リストア実行（POSTGRES_PASSWORDとPOSTGRES_USERを直接指定）
docker exec -i -e PGPASSWORD="your_password_here" postgres_db psql -U postgres -d postgres < $backupFile
```

**注意事項:**
- リストア前に既存のデータベースのバックアップを取ることを推奨します
- リストア中はデータベースへの接続を避けてください
- 大きなバックアップファイルの場合は、処理に時間がかかる場合があります

### 初期化スクリプト

`setup/init-scripts/` ディレクトリに `.sql` ファイルを配置すると、コンテナの初回起動時に自動実行されます。

- ファイル名は実行順序に影響します（01-init.sql → 02-tables.sql → 03-indexes.sql → 04-seed-data.sql）
- 既存のデータベースには実行されません（初回のみ）

**現在の構成:**
- `01-init.sql`: 拡張機能の有効化（pg_trgm, pgvector）
- `02-tables.sql`: 商品マスタテーブルと在庫テーブルの作成（embeddingカラム含む）
- `03-indexes.sql`: パフォーマンス最適化用インデックス（ベクトル検索用インデックス含む）
- `04-seed-data.sql`: サンプルデータ（通販サイト風商品、8カテゴリ）
- `05-vector-migration.sql`: ベクトル検索対応マイグレーション（既存DB用、初回起動時は不要）
- `06-vector-search-examples.sql`: ベクトル検索のサンプルクエリ（参考用）
- `07-add-embeddings.sql`: ベクトルデータ追加の説明と確認用スクリプト

**既存データベースにサンプルデータを投入する場合:**

初期化スクリプトは初回起動時のみ実行されるため、既存のデータベースにサンプルデータを投入する場合は手動で実行してください：

**方法1: ファイルをコンテナにコピーして実行（推奨・文字エンコーディング問題を回避）**
```powershell
# パスワードを設定（.envから読み込むか直接指定）
$password = (Get-Content .env | Select-String "POSTGRES_PASSWORD" | ForEach-Object { $_.Line.Split('=')[1] })
# または直接指定: $password = "your_password_here"

$dbName = (Get-Content .env | Select-String "POSTGRES_DB" | ForEach-Object { $_.Line.Split('=')[1] })
if (-not $dbName) { $dbName = "shopDB" }

# データベースの存在確認と作成（存在しない場合）
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d postgres -c "SELECT 1 FROM pg_database WHERE datname='$dbName'" | Select-String -Pattern "1" -Quiet
if (-not $?) {
    Write-Host "データベース '$dbName' が存在しないため、作成します..."
    docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d postgres -c "CREATE DATABASE $dbName;"
}

# テーブルが存在しない場合は作成（01-init.sql, 02-tables.sql, 03-indexes.sqlを順に実行）
Write-Host "テーブルを作成中..."
docker cp setup\init-scripts\01-init.sql postgres_db:/tmp/01-init.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/01-init.sql

docker cp setup\init-scripts\02-tables.sql postgres_db:/tmp/02-tables.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/02-tables.sql

docker cp setup\init-scripts\03-indexes.sql postgres_db:/tmp/03-indexes.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/03-indexes.sql

# サンプルデータを投入
Write-Host "サンプルデータを投入中..."
docker cp setup\init-scripts\04-seed-data.sql postgres_db:/tmp/seed-data.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/seed-data.sql

# 一時ファイルを削除
docker exec postgres_db rm -f /tmp/01-init.sql /tmp/02-tables.sql /tmp/03-indexes.sql /tmp/seed-data.sql

Write-Host "完了しました！"
```

**方法2: UTF-8エンコーディングを明示的に指定**
```powershell
# パスワードを設定
$password = (Get-Content .env | Select-String "POSTGRES_PASSWORD" | ForEach-Object { $_.Line.Split('=')[1] })
$dbName = (Get-Content .env | Select-String "POSTGRES_DB" | ForEach-Object { $_.Line.Split('=')[1] })
if (-not $dbName) { $dbName = "shopDB" }

# UTF-8エンコーディングを明示的に指定して実行
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Get-Content setup\init-scripts\04-seed-data.sql -Encoding UTF8 | docker exec -i -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName
```

**方法3: パスワードを直接指定（最も簡単）**
```powershell
# パスワードとデータベース名を設定
$password = "masterkey"
$dbName = "shopDB"

# データベースの存在確認と作成（存在しない場合）
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d postgres -c "SELECT 1 FROM pg_database WHERE datname='$dbName'" | Select-String -Pattern "1" -Quiet
if (-not $?) {
    Write-Host "データベース '$dbName' が存在しないため、作成します..."
    docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d postgres -c "CREATE DATABASE $dbName;"
}

# テーブルが存在しない場合は作成
Write-Host "テーブルを作成中..."
docker cp setup\init-scripts\01-init.sql postgres_db:/tmp/01-init.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/01-init.sql

docker cp setup\init-scripts\02-tables.sql postgres_db:/tmp/02-tables.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/02-tables.sql

docker cp setup\init-scripts\03-indexes.sql postgres_db:/tmp/03-indexes.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/03-indexes.sql

# サンプルデータを投入
Write-Host "サンプルデータを投入中..."
docker cp setup\init-scripts\04-seed-data.sql postgres_db:/tmp/seed-data.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/seed-data.sql

# 一時ファイルを削除
docker exec postgres_db rm -f /tmp/01-init.sql /tmp/02-tables.sql /tmp/03-indexes.sql /tmp/seed-data.sql

Write-Host "完了しました！"
```

## 📊 データベーススキーマ

### テーブル構成

**products（商品マスタ）**
- 商品コード、商品名、説明、価格、ステータスなど
- `embedding` カラム: AIで生成したベクトル（1024次元、`BAAI/bge-m3`）

**product_stocks（在庫テーブル）**
- 商品ごとの在庫数を管理

### サンプルデータ

通販サイト風の商品データ（41件）が初期データとして登録されます。

- 家電・PC、ファッション、食品、インテリア・生活
- 美容・コスメ、スポーツ、本・メディア、おもちゃ・ホビー

## 🔍 ベクトル検索（AI検索）

### 概要

pgvector と Sentence Transformers を用い、商品名・説明の意味的類似度で検索します。

**初回起動時に自動設定される内容:**

- `vector` / `pg_trgm` 拡張
- `products.embedding vector(1024)` カラム
- HNSW インデックス（`idx_products_embedding_hnsw`）

詳細仕様は [`.cursor/order/projectFeatures.mdc`](.cursor/order/projectFeatures.mdc) を参照してください。

### 使用モデル

**BAAI/bge-m3**（本番パス）

| 項目 | 値 |
|------|-----|
| 次元数 | 1024（DB スキーマと一致） |
| 入力 | `{商品名} {説明}` |
| 正規化 | L2 正規化（`normalize_embeddings=True`） |
| プレフィックス | **不要**（e5 系とは異なる） |

CLI では `--model` で変更可能。Web API は `BAAI/bge-m3` 固定。

### スクリプト

#### アプリケーション

| スクリプト | 説明 | 使用方法 |
|------------|------|---------|
| `generate-embeddings.py` | 未設定商品のベクトル生成 | `python app/scripts/generate-embeddings.py` |
| `search-similar-products.py` | 類似商品検索（CLI） | `python app/scripts/search-similar-products.py "クエリ"` |
| `run-web-ui.py` | Web UI / API 起動 | `python app/scripts/run-web-ui.py` |

#### セットアップ

| スクリプト | 説明 |
|------------|------|
| `setup-venv.ps1` / `.sh` | 仮想環境 + 依存インストール |
| `load-env.ps1` | `.env` を PowerShell へ読込 |
| `align-postgres-password-with-env.ps1` | DB パスワードを `.env` と同期 |
| `run-example.ps1` | 対話メニュー |
| `setup/examples/e5-usage-example.py` | **参考用**（e5 モデル、本番パス外） |

### ベクトル生成

```bash
python app/scripts/generate-embeddings.py
python app/scripts/generate-embeddings.py --model BAAI/bge-m3
```

- 対象: `embedding IS NULL` の商品のみ
- 初回実行時: Hugging Face からモデルをダウンロード（`~/.cache/huggingface/`）

**Web UI:** `#/admin/operations` から Embedding ジョブ（`missing` / `all`）を開始できます。

### 類似検索

**CLI（テキスト）**

```bash
python app/scripts/search-similar-products.py "ワイヤレスイヤホン"
python app/scripts/search-similar-products.py "コーヒー" --limit 5 --min-similarity 0.7
```

**CLI（商品比較・基準商品を除外）**

```bash
python app/scripts/search-similar-products.py --compare-products --product-id 1
```

**Web UI:** カタログはヘッダー検索（ベクトル類似検索）。管理は `#/admin/search` → テキスト検索または商品 ID 検索

### Web UI 画面

| ルート | 内容 |
|--------|------|
| `#/catalog` | 商品一覧（Vector Search Store） |
| `#/catalog/search` | 類似検索結果 |
| `#/catalog/products/:id` | 商品詳細 + 類似商品 |
| `#/admin/dashboard` | 商品数・embedding 状況・ヘルスチェック |
| `#/admin/products` | 商品一覧・フィルタ |
| `#/admin/search` | 類似検索（パラメータ調整可） |
| `#/admin/operations` | Embedding 一括生成ジョブ |

### 既存 DB へのベクトル列追加

```powershell
docker cp setup\init-scripts\05-vector-migration.sql postgres_db:/tmp/vector-migration.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/vector-migration.sql
docker cp setup\init-scripts\03-indexes.sql postgres_db:/tmp/03-indexes.sql
docker exec -e PGPASSWORD=$password postgres_db psql -U postgres -d $dbName -f /tmp/03-indexes.sql
```

### Python コード例（bge-m3）

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("BAAI/bge-m3")
query = "ワイヤレスイヤホン"
products = ["ワイヤレスイヤホン ANC ...", "スマートウォッチ Pro ..."]

q_emb = model.encode([query], normalize_embeddings=True)
p_emb = model.encode(products, normalize_embeddings=True)
similarities = model.similarity(q_emb, p_emb)[0]
```

### SQL でのベクトル検索

```sql
SELECT id, product_code, name,
       1 - (embedding <=> '[...]'::vector(1024)) AS similarity
FROM products
WHERE embedding IS NOT NULL
ORDER BY embedding <=> '[...]'::vector(1024)
LIMIT 10;
```

演算子: `<=>` コサイン距離 / `<->` L2 / `<#>` 負の内積。サンプルは `setup/init-scripts/06-vector-search-examples.sql`。

**補足:** API は pgvector SQL（`<=>` + HNSW）で検索。CLI は引き続き Python 側の全件スキャンです。

### 参考: e5 モデル（本番パス外）

`intfloat/multilingual-e5-large` では `query:` / `passage:` プレフィックスが必要です。

```bash
python setup/examples/e5-usage-example.py
```

### 参考

- [pgvector](https://github.com/pgvector/pgvector)
- [BAAI/bge-m3 (Hugging Face)](https://huggingface.co/BAAI/bge-m3)
- [Sentence Transformers](https://www.sbert.net/)
## 🚢 デプロイ

本番サーバーへの載せ方、systemd / Nginx の例、更新手順は **[DEPLOY.md](DEPLOY.md)** を参照してください。

---

## 🔧 トラブルシューティング

### コンテナが起動しない

```bash
# ログを確認
docker-compose logs postgres

# コンテナの状態を確認
docker ps -a
```

### データベースに接続できない

```bash
# コンテナ内で直接確認
docker exec -it postgres_db psql -U postgres

# または接続確認
docker exec postgres_db pg_isready -U postgres
```

### ホスト（Python/pgAdmin）から `password authentication failed` になる

既存の `postgres_data` ボリュームがある場合、データディレクトリ作成時に設定された `postgres` ユーザのパスワードが、現在の `.env` の `POSTGRES_PASSWORD` と一致しないことがあります。コンテナ内の `psql` は `trust` などでパスワードなしでも通ることがあり、気づきにくいです。

**対処（推奨）:** プロジェクトルートで PowerShell を開き、次を実行します。

```powershell
.\setup\scripts\align-postgres-password-with-env.ps1
```

**手動で揃える例:**

```bash
docker exec postgres_db psql -U postgres -d postgres -c "ALTER USER postgres WITH PASSWORD 'your_password_here';"
```

（`your_password_here` は `.env` の `POSTGRES_PASSWORD` と同じ値にしてください。）

### コンテナ名 `postgres_db` が既に使われている

別の Compose や古いコンテナが残っていると `Conflict. The container name "/postgres_db" is already in use` になります。不要なコンテナを削除するか、`docker compose down` などで整理してから再度 `docker compose up -d` してください。

### `volume ... already exists but was created for project "..."` と表示される

名前付きボリュームを過去の Compose プロジェクトで作成したことが原因です。データを維持したまま使う場合は、警告のみで動作に問題がないことが多いです。本リポジトリの `docker-compose.yml` 先頭に `name: vector-search` を指定し、プロジェクト名を固定しています。

### パスワードを忘れた

```bash
# コンテナを停止
docker-compose down

# ボリュームを削除（⚠️ データが失われます）
docker volume rm postgres_data

# .envファイルのパスワードを更新
# コンテナを再起動
docker-compose up -d
```

### ディスク容量の問題

```bash
# ボリュームのサイズ確認
docker system df -v

# 不要なリソースの削除
docker system prune -a --volumes
```

## 📚 参考リンク

- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)
- [Docker Compose公式ドキュメント](https://docs.docker.com/compose/)
- [pgvector公式ドキュメント](https://github.com/pgvector/pgvector)
- [BAAI/bge-m3 (Hugging Face)](https://huggingface.co/BAAI/bge-m3)
- [Sentence Transformers公式ドキュメント](https://www.sbert.net/)

## 📝 関連ドキュメント

- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - プロジェクト構造
- [FLOW.md](FLOW.md) - セットアップ・実行フロー
- `.cursor/order/projectFeatures.mdc` - 機能仕様 SSOT（エージェント向け）
- `.cursor/order/TechStack.mdc` - 技術スタック SSOT（エージェント向け）

