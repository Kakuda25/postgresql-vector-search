async function api(path, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 30000);
  try {
    const res = await fetch(path, {
      headers: { "Content-Type": "application/json" },
      signal: controller.signal,
      ...options,
    });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.detail || `HTTP ${res.status}`);
    }
    return res.json();
  } catch (err) {
    if (err.name === "AbortError") throw new Error("タイムアウト: サーバーの応答がありません");
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

function yen(value) {
  return new Intl.NumberFormat("ja-JP", { style: "currency", currency: "JPY", maximumFractionDigits: 0 }).format(value);
}

function td(text) {
  const el = document.createElement("td");
  el.textContent = text ?? "-";
  return el;
}

async function withButton(btn, fn) {
  btn.disabled = true;
  try {
    await fn();
  } finally {
    btn.disabled = false;
  }
}

const CATEGORY_PLACEHOLDER = {
  electronics: { bg: "#dbeafe", label: "家電" },
  fashion: { bg: "#fce7f3", label: "ファッション" },
  food: { bg: "#dcfce7", label: "食品" },
  home: { bg: "#fef3c7", label: "生活" },
  beauty: { bg: "#f3e8ff", label: "美容" },
  sports: { bg: "#cffafe", label: "スポーツ" },
  books: { bg: "#ffe4e6", label: "本" },
  toys: { bg: "#fef9c3", label: "ホビー" },
};

let categoryLabels = {};

function displayCategory(item) {
  return item.categoryLabel || categoryLabels[item.category] || item.category || "-";
}

async function loadCategoryMeta() {
  const data = await api("/api/meta/categories");
  categoryLabels = Object.fromEntries(data.items.map((item) => [item.value, item.label]));
  return data.items;
}

function fillCategorySelect(selectId, items) {
  const select = document.getElementById(selectId);
  if (!select) return;
  const current = select.value;
  select.innerHTML = '<option value="">全カテゴリ</option>';
  items.forEach(({ value, label }) => {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = label;
    select.appendChild(option);
  });
  if ([...select.options].some((opt) => opt.value === current)) {
    select.value = current;
  }
}

function productImageMarkup(item, className = "product-image") {
  if (item.imageUrl) {
    const img = document.createElement("img");
    img.className = className;
    img.src = item.imageUrl;
    img.alt = item.name;
    img.loading = "lazy";
    return img;
  }
  const placeholder = document.createElement("div");
  placeholder.className = `${className} product-placeholder`;
  const meta = CATEGORY_PLACEHOLDER[item.category] || { bg: "#e2e8f0", label: "商品" };
  placeholder.style.background = meta.bg;
  placeholder.textContent = meta.label;
  return placeholder;
}

function createProductCard(item) {
  const card = document.createElement("div");
  card.className = "product-card";

  const media = document.createElement("div");
  media.className = "product-card-media";
  media.appendChild(productImageMarkup(item, "product-card-image"));

  const body = document.createElement("div");
  body.className = "product-card-body";

  const category = document.createElement("div");
  category.className = "product-card-category";
  category.textContent = displayCategory(item);

  const name = document.createElement("div");
  name.className = "product-card-name";
  name.textContent = item.name;

  const price = document.createElement("div");
  price.className = "product-card-price";
  price.textContent = yen(item.price);

  body.appendChild(category);
  body.appendChild(name);
  body.appendChild(price);
  card.appendChild(media);
  card.appendChild(body);
  return card;
}

const CATALOG_SEARCH_DEFAULTS = { topK: 10, scoreThreshold: 0 };

async function runSimilaritySearch({ type, text, productId, category }) {
  const payload = {
    type,
    topK: CATALOG_SEARCH_DEFAULTS.topK,
    scoreThreshold: CATALOG_SEARCH_DEFAULTS.scoreThreshold,
  };
  if (category) payload.category = category;
  if (type === "product") payload.productId = productId;
  else payload.text = text;

  return api("/api/similarity/search", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}
