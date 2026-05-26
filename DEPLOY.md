# デプロイ手順

Vector Search（Vector Search Store + 管理画面）のデプロイ方法をまとめたドキュメントです。

## 構成概要

| コンポーネント | 実行方式 | ポート（既定） |
|----------------|----------|----------------|
| PostgreSQL 16 + pgvector | Docker Compose | 5432 |
| pgAdmin（任意） | Docker Compose | 5050 |
| FastAPI + Web UI | ホスト上の Python（Uvicorn） | 8000 |

- **DB** は Docker コンテナで常時起動
- **アプリ**（API / 静的 UI / 埋め込みモデル）はホスト OS 上の Python 仮想環境で起動
- 初回は Embedding 生成が必要（シード商品の `embedding` は NULL）

## 必要環境

| 項目 | 推奨 |
|------|------|
| OS | Linux / Windows / macOS |
| Docker | Docker Engine 24+、Compose v2 |
| Python | 3.10 以上 |
| メモリ | 4 GB 以上（`BAAI/bge-m3` 読込時） |
| ディスク | 10 GB 以上（Docker イメージ + モデルキャッシュ） |

---

## 1. 初回デプロイ（ローカル / サーバー共通）

### 1-1. リポジトリ取得

```bash
git clone https://github.com/Kakuda25/vector-search.git
cd vector-search
```

### 1-2. 環境変数

```bash
cp env.template .env
```

`.env` を編集し、最低限以下を設定します。

| 変数 | 説明 |
|------|------|
| `POSTGRES_PASSWORD` | DB パスワード（必須） |
| `PGADMIN_PASSWORD` | pgAdmin 利用時のみ |

アプリから DB へ接続する際の追加変数（`.env` に追記可）:

| 変数 | 既定 | 説明 |
|------|------|------|
| `POSTGRES_HOST` | `localhost` | DB ホスト |
| `POSTGRES_PORT` | `5432` | DB ポート |
| `POSTGRES_DB` | `shopDB` | DB 名 |
| `POSTGRES_USER` | `postgres` | DB ユーザー |

> `.env` は Git に含めません。本番サーバーでは手動配置またはシークレット管理で渡してください。

### 1-3. データベース起動

```bash
docker compose up -d
```

初回起動時、`setup/init-scripts/` が自動実行され、スキーマ・シード（41 商品）が投入されます。

### 1-4. Python 環境

**Windows（PowerShell）**

```powershell
.\setup\scripts\setup-venv.ps1
.\venv\Scripts\Activate.ps1
```

**Linux / macOS**

```bash
./setup/scripts/setup-venv.sh
source venv/bin/activate
```

### 1-5. Embedding 生成

Web UI の類似検索を使う前に、ベクトルを生成します。

```bash
# CLI（未生成のみ）
python app/scripts/generate-embeddings.py
```

または Web UI 起動後、管理画面 `#/admin/operations` からジョブ実行（`missing` / `all`）。

初回は Hugging Face から `BAAI/bge-m3` をダウンロードするため、ネットワーク接続と数分の時間が必要です。

### 1-6. Web UI 起動

```bash
python app/scripts/run-web-ui.py
```

| URL | 画面 |
|-----|------|
| http://localhost:8000/#/catalog | Vector Search Store（カタログ） |
| http://localhost:8000/#/admin/dashboard | 管理画面 |

---

## 2. 本番サーバーへのデプロイ

現状、専用の Dockerfile / PaaS 設定はありません。**1 台の VM** に Docker（DB）+ Python（アプリ）を載せる構成を想定しています。

### 2-1. 推奨手順

1. サーバーに Docker / Python 3.10+ をインストール
2. リポジトリを clone
3. [初回デプロイ](#1-初回デプロイローカル--サーバー共通) と同様に `.env` → `docker compose up -d` → venv → Embedding → Web UI
4. ファイアウールで **8000**（またはリバースプロキシの 443）のみ公開
5. PostgreSQL ポート **5432** は外部公開しない（`localhost` バインド推奨）

### 2-2. systemd で常時起動（Linux 例）

`/etc/systemd/system/vector-search.service`

```ini
[Unit]
Description=Vector Search Web UI
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/opt/vector-search
EnvironmentFile=/opt/vector-search/.env
ExecStart=/opt/vector-search/venv/bin/python app/scripts/run-web-ui.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vector-search
```

### 2-3. Nginx リバースプロキシ（任意）

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

HTTPS は Let's Encrypt 等で証明書を設定してください。

---

## 3. 更新手順

```bash
cd vector-search
git pull origin main

# DB スキーマ追加がある場合（既存 DB）
# setup/init-scripts/ の新規 SQL を手動適用

docker compose up -d

source venv/bin/activate   # Windows: .\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# 必要に応じて Embedding 再生成
python app/scripts/generate-embeddings.py

# systemd 利用時
sudo systemctl restart vector-search
```

---

## 4. 既存 DB へのマイグレーション

Compose **初回起動後** に init スクリプトが追加された場合、手動で SQL を実行します。

```bash
docker exec -i postgres_db psql -U postgres -d shopDB < setup/init-scripts/08-add-category.sql
docker exec -i postgres_db psql -U postgres -d shopDB < setup/init-scripts/09-embedding-jobs-table.sql
```

---

## 5. トラブルシューティング

| 症状 | 対処 |
|------|------|
| `password authentication failed` | `.env` のパスワードと DB を `setup/scripts/align-postgres-password-with-env.ps1` で同期 |
| 類似検索が空 | Embedding 未生成 → `generate-embeddings.py` または管理画面ジョブ |
| モデル DL が遅い / 失敗 | ネットワーク・プロキシ確認。HF キャッシュは `~/.cache/huggingface` |
| ポート 8000 が使用中 | `run-web-ui.py` の Uvicorn ポートを変更するか、競合プロセスを停止 |
| pgAdmin に接続できない | `setup/scripts/configure-pgadmin.ps1` を実行 |

---

## 6. セキュリティ上の注意

- `.env` / DB パスワードをリポジトリにコミットしない
- 本番では pgAdmin を公開しない、または VPN 内に限定
- 管理画面に認証は未実装 — インターネット公開時は Basic 認証・VPN・IP 制限を検討
- Embedding ジョブは CPU/GPU 負荷が高い — 同時実行数に注意

---

## 関連ドキュメント

- [README.md](README.md) — クイックスタート・操作ガイド
- [FLOW.md](FLOW.md) — 処理フロー
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) — ディレクトリ構成
