#!/usr/bin/env python3
"""
全商品を削除し、通販サイト風のサンプル商品（41件）を投入します。

使用方法:
    python app/scripts/reset-test-products.py

投入後、embedding は NULL です。必要に応じて:
    python app/scripts/generate-embeddings.py
"""

import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from app.utils.database import create_connection

SEED_SQL = project_root / "setup" / "init-scripts" / "10-test-products-seed.sql"


def main() -> None:
    sql = SEED_SQL.read_text(encoding="utf-8")
    conn = create_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()

        cur.execute("SELECT COUNT(*) FROM products")
        total = cur.fetchone()[0]
        cur.execute(
            """
            SELECT category, COUNT(*)
            FROM products
            GROUP BY category
            ORDER BY category
            """
        )
        by_category = cur.fetchall()
    finally:
        conn.close()

    print(f"\n完了: {total} 件のテスト商品を投入しました（embedding は未生成）。")
    print("カテゴリ内訳:")
    for category, count in by_category:
        print(f"  {category}: {count}")
    print("\n次のステップ: python app/scripts/generate-embeddings.py")


if __name__ == "__main__":
    main()
