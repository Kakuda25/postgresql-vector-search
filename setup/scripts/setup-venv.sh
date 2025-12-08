#!/bin/bash
# Bashスクリプト: 仮想環境のセットアップと実行（Linux/Mac用）
# 使用方法: bash scripts/setup-venv.sh

set -e

echo "========================================"
echo "仮想環境のセットアップ"
echo "========================================"

# 1. Pythonのバージョン確認
echo ""
echo "[1/6] Pythonのバージョンを確認中..."
if ! command -v python3 &> /dev/null; then
    echo "エラー: Python3がインストールされていません。"
    exit 1
fi
python3 --version
echo "✓ Pythonが確認できました"

# 2. 仮想環境の作成
echo ""
echo "[2/6] 仮想環境を作成中..."
if [ -d "venv" ]; then
    echo "仮想環境 'venv' は既に存在します。削除して再作成しますか？ (y/n)"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        rm -rf venv
        python3 -m venv venv
        echo "✓ 仮想環境を再作成しました"
    else
        echo "既存の仮想環境を使用します"
    fi
else
    python3 -m venv venv
    echo "✓ 仮想環境を作成しました"
fi

# 3. 仮想環境の有効化
echo ""
echo "[3/6] 仮想環境を有効化中..."
source venv/bin/activate
echo "✓ 仮想環境を有効化しました"

# 4. pipのアップグレード
echo ""
echo "[4/6] pipをアップグレード中..."
pip install --upgrade pip
echo "✓ pipをアップグレードしました"

# 5. 必要なライブラリのインストール
echo ""
echo "[5/6] 必要なライブラリをインストール中..."
echo "（時間がかかる場合があります）"
pip install -r requirements.txt
echo "✓ ライブラリのインストールが完了しました"

# 6. 環境変数の確認
echo ""
echo "[6/6] 環境変数の確認..."
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "⚠️  警告: POSTGRES_PASSWORD環境変数が設定されていません"
    echo "以下のコマンドで設定してください:"
    echo "export POSTGRES_PASSWORD='your_password'"
    echo ""
    echo "または、.envファイルから読み込む:"
    echo "export \$(grep -v '^#' .env | xargs)"
else
    echo "✓ POSTGRES_PASSWORDが設定されています"
fi

echo ""
echo "========================================"
echo "セットアップ完了！"
echo "========================================"
echo ""
echo "次のステップ:"
echo "1. 環境変数を設定:"
echo "   export POSTGRES_PASSWORD='your_password'"
echo ""
echo "2. ベクトルを生成:"
echo "   python scripts/generate-embeddings.py --sentence-transformers --sentence-model intfloat/multilingual-e5-large"
echo ""
echo "3. 類似商品を検索:"
echo "   python scripts/search-similar-products.py 'ハンドピース'"
echo ""
echo "仮想環境を無効化するには: deactivate"

