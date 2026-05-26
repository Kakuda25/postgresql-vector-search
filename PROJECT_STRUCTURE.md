# プロジェクト構造

仕様の SSOT は `.cursor/order/projectFeatures.mdc` および `.cursor/order/TechStack.mdc` を参照してください。

## ディレクトリ構成

```
vector-search/
├── .cursor/                        # Cursor 設定・仕様 SSOT
│   ├── order/                      # TechStack / projectFeatures / 作業手順
│   └── docs/                       # 作業記録・設計メモ（SSOT ではない）
│
├── setup/                          # 環境構築用（デプロイ対象外）
│   ├── init-scripts/               # DB 初期化 SQL（Docker 初回起動時に自動実行）
│   │   ├── 01-init.sql
│   │   ├── 02-tables.sql
│   │   ├── 03-indexes.sql
│   │   ├── 04-seed-data.sql
│   │   ├── 05-vector-migration.sql
│   │   ├── 06-vector-search-examples.sql
│   │   └── 07-add-embeddings.sql
│   ├── scripts/                    # venv セットアップ・env 読込等
│   │   ├── setup-venv.ps1 / .sh
│   │   ├── align-postgres-password-with-env.ps1
│   │   ├── load-env.ps1
│   │   ├── run-example.ps1
│   │   └── setup.sh
│   └── examples/
│       └── e5-usage-example.py     # e5 モデル参考用（本番パス外）
│
├── app/                            # アプリケーション（デプロイ対象）
│   ├── api/
│   │   └── main.py                 # FastAPI（REST + 静的 UI 配信）
│   ├── scripts/
│   │   ├── generate-embeddings.py
│   │   ├── search-similar-products.py
│   │   └── run-web-ui.py
│   ├── utils/
│   │   ├── database.py
│   │   ├── env_loader.py
│   │   └── vector_utils.py
│   └── web/                        # Web UI（HTML / JS / CSS）
│       ├── index.html
│       ├── tokens.css
│       ├── catalog.css
│       ├── admin.css
│       ├── shared.js
│       ├── router.js
│       ├── catalog.js
│       ├── admin.js
│       └── app.js
│
├── docker-compose.yml
├── env.template
├── requirements.txt
├── README.md
└── FLOW.md
```

## ディレクトリの役割

### setup/

環境構築・検証用。本番デプロイには含めない。

- **init-scripts/**: スキーマ・シード・インデックス（初回コンテナ起動時のみ）
- **scripts/**: 仮想環境、Docker 補助、対話メニュー
- **examples/**: 別モデル（e5）の参考サンプル

### app/

実行時コード。

- **api/**: FastAPI サーバー（ダッシュボード / 商品 / 類似検索 / Embedding ジョブ API）
- **scripts/**: CLI（埋め込み生成・検索・Web 起動）
- **utils/**: DB 接続、環境変数、ベクトル処理
- **web/**: ブラウザ UI（hash ルーティング）

## 使用方法

### 環境構築

```powershell
.\setup\scripts\setup-venv.ps1
docker-compose up -d
python app/scripts/generate-embeddings.py
python app/scripts/run-web-ui.py
```

### アプリケーションからの import

```python
from app.utils.database import create_connection
from app.utils.vector_utils import adjust_dimension, VECTOR_DIMENSION
```

## 注意事項

- `setup/` と `app/` は用途で分離。デプロイ時は `app/` + `requirements.txt` が中心
- 埋め込みモデルは **`BAAI/bge-m3`（1024 次元）** が本番パス
- 詳細仕様は `.cursor/order/projectFeatures.mdc` を参照
