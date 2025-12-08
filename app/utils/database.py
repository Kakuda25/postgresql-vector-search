"""
データベース接続ユーティリティ
データベース接続の共通処理
"""

import psycopg2
import sys
from app.utils.env_loader import get_db_config


def create_connection() -> psycopg2.extensions.connection:
    """データベース接続を作成
    
    Returns:
        データベース接続オブジェクト
    
    Raises:
        SystemExit: パスワードが設定されていない場合、または接続に失敗した場合
    """
    config = get_db_config()
    
    if not config['password']:
        print("エラー: POSTGRES_PASSWORD環境変数が設定されていません。")
        print(".envファイルを確認するか、環境変数を設定してください:")
        print('  $env:POSTGRES_PASSWORD = "your_password"')
        print("または:")
        print('  Get-Content .env | ForEach-Object { if ($_ -match "^POSTGRES_PASSWORD=(.+)$") { $env:POSTGRES_PASSWORD = $matches[1] } }')
        sys.exit(1)
    
    try:
        connection = psycopg2.connect(
            host=config['host'],
            port=config['port'],
            database=config['database'],
            user=config['user'],
            password=config['password']
        )
        print(f"データベースに接続しました: {config['database']}")
        return connection
    except psycopg2.OperationalError as e:
        print(f"データベース接続エラー: {str(e)}")
        print(f"接続情報: host={config['host']}, port={config['port']}, database={config['database']}, user={config['user']}")
        sys.exit(1)
    except Exception as e:
        print(f"予期しないエラーが発生しました: {str(e)}")
        sys.exit(1)

