"""商品カテゴリ定義（product_code プレフィックスと API 値の対応）"""

from __future__ import annotations

PRODUCT_CATEGORIES: list[dict[str, str]] = [
    {"value": "electronics", "label": "家電・PC"},
    {"value": "fashion", "label": "ファッション"},
    {"value": "food", "label": "食品"},
    {"value": "home", "label": "インテリア・生活"},
    {"value": "beauty", "label": "美容・コスメ"},
    {"value": "sports", "label": "スポーツ"},
    {"value": "books", "label": "本・メディア"},
    {"value": "toys", "label": "おもちゃ・ホビー"},
]

CATEGORY_LABEL_BY_VALUE = {item["value"]: item["label"] for item in PRODUCT_CATEGORIES}

BACKFILL_CATEGORY_SQL = """
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
WHERE category IS NULL
"""


def category_label(value: str | None) -> str | None:
    if not value:
        return None
    return CATEGORY_LABEL_BY_VALUE.get(value, value)
