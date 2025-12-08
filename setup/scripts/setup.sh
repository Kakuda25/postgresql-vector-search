#!/bin/bash
# セットアップスクリプト

set -euo pipefail

echo "PostgreSQL Docker環境のセットアップを開始します..."

# .envファイルの確認
if [ ! -f .env ]; then
    echo ".envファイルが見つかりません。env.templateから作成します..."
    cp env.template .env
    echo "⚠️  .envファイルを編集して、パスワードを設定してください"
    echo "編集後、このスクリプトを再実行してください"
    exit 1
fi

# 必要なディレクトリの作成
echo "必要なディレクトリを作成します..."
mkdir -p setup/init-scripts

# スクリプトに実行権限を付与
echo "スクリプトに実行権限を付与します..."
chmod +x setup/scripts/*.sh 2>/dev/null || true

# Docker Composeの起動
echo "Docker Composeでコンテナを起動します..."
docker-compose up -d

# 起動待機
echo "コンテナの起動を待機します..."
sleep 5

echo "✅ セットアップ完了！"
echo ""
echo "接続情報:"
echo "  ホスト: localhost"
echo "  ポート: $(grep POSTGRES_PORT .env | cut -d '=' -f2 || echo '5432')"
echo "  データベース: $(grep POSTGRES_DB .env | cut -d '=' -f2 || echo 'dentalDB')"
echo "  ユーザー: $(grep POSTGRES_USER .env | cut -d '=' -f2 || echo 'postgres')"
echo ""
echo "pgAdmin: http://localhost:$(grep PGADMIN_PORT .env | cut -d '=' -f2 || echo '5050')"
echo ""
echo "接続確認: docker exec -it postgres_db psql -U postgres -d dentalDB"

