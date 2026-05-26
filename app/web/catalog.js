const CATEGORY_ICON_PATHS = {
  electronics: [
    { d: "M4 6h16v10H4z" },
    { d: "M2 10h20" },
    { d: "M8 18v2" },
    { d: "M16 18v2" },
  ],
  fashion: [
    { d: "M6 3h12l-1 4H7L6 3z" },
    { d: "M6 7l-2 13h16L18 7" },
    { d: "M12 7v13" },
  ],
  food: [
    { d: "M18 8h1a4 4 0 0 1 0 8h-1" },
    { d: "M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z" },
    { d: "M6 1v3" },
    { d: "M10 1v3" },
    { d: "M14 1v3" },
  ],
  home: [
    { d: "m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" },
    { d: "M9 22V12h6v10" },
  ],
  beauty: [
    { d: "M12 3l1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3z" },
    { d: "M5 19h14" },
  ],
  sports: [{ d: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z" }, { d: "M12 2v20" }, { d: "M2 12h20" }],
  books: [
    { d: "M4 19.5A2.5 2.5 0 0 1 6.5 17H20" },
    { d: "M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" },
  ],
  toys: [
    { d: "M6 12h4" },
    { d: "M8 10v4" },
    { d: "M15 13h.01" },
    { d: "M18 11h.01" },
    { d: "M17 16h.01" },
    { d: "M14 16h.01" },
    { d: "M15.5 3.5a3 3 0 0 0-4 4L3 17l4 4 8.5-8.5a3 3 0 0 0 4-4z" },
  ],
};

function createCategoryIconSvg(category) {
  const paths = CATEGORY_ICON_PATHS[category] || CATEGORY_ICON_PATHS.home;
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("width", "24");
  svg.setAttribute("height", "24");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("fill", "none");
  svg.setAttribute("stroke", "currentColor");
  svg.setAttribute("stroke-width", "2");
  svg.setAttribute("stroke-linecap", "round");
  svg.setAttribute("stroke-linejoin", "round");
  svg.setAttribute("aria-hidden", "true");
  paths.forEach(({ d }) => {
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.setAttribute("d", d);
    svg.appendChild(path);
  });
  return svg;
}

function createNavIconSvg(category) {
  const svg = createCategoryIconSvg(category);
  svg.setAttribute("width", "18");
  svg.setAttribute("height", "18");
  return svg;
}

let catalogCategories = [];
let catalogLoaded = {
  categories: false,
  home: false,
  search: false,
  product: false,
};

function setCatalogSearchInputs(value) {
  document.querySelectorAll("[data-catalog-search-input]").forEach((input) => {
    input.value = value;
  });
}

function getCatalogSearchInputValue() {
  const input = document.querySelector("[data-catalog-search-input]");
  return input ? input.value.trim() : "";
}

function validateCatalogQuery(query) {
  if (!query) return "検索クエリを入力してください。";
  if (query.length > 500) return "検索クエリは500文字以内で入力してください。";
  return null;
}

function renderCategorySidebar(categories, activeCategory) {
  const nav = document.getElementById("catalogCategoryNav");
  if (!nav) return;
  nav.innerHTML = "";

  const allLink = document.createElement("a");
  allLink.href = "#/catalog";
  allLink.appendChild(createNavIconSvg("home"));
  allLink.appendChild(document.createTextNode("すべて"));
  allLink.classList.toggle("active", !activeCategory);
  nav.appendChild(allLink);

  categories.forEach(({ value, label }) => {
    const link = document.createElement("a");
    link.href = buildCatalogHomeHash(value);
    link.appendChild(createNavIconSvg(value));
    link.appendChild(document.createTextNode(label));
    link.classList.toggle("active", activeCategory === value);
    nav.appendChild(link);
  });
}

function renderProductGrid(container, items) {
  container.innerHTML = "";
  if (!items.length) {
    const empty = document.createElement("div");
    empty.className = "catalog-empty";
    empty.textContent = "条件に一致する商品がありません。";
    container.appendChild(empty);
    return;
  }
  const grid = document.createElement("div");
  grid.className = "product-grid";
  items.forEach((item) => grid.appendChild(createProductCard(item)));
  container.appendChild(grid);
}

async function ensureCatalogCategories() {
  if (catalogLoaded.categories) return catalogCategories;
  catalogCategories = await loadCategoryMeta();
  catalogLoaded.categories = true;
  return catalogCategories;
}

async function loadCatalogHome(category) {
  const state = document.getElementById("catalogHomeState");
  const gridRoot = document.getElementById("catalogHomeGrid");
  state.textContent = "読込中...";
  gridRoot.innerHTML = "";

  const categories = await ensureCatalogCategories();
  renderCategorySidebar(categories, category || "");

  const params = new URLSearchParams();
  if (category) params.set("category", category);
  const data = await api(`/api/products?${params.toString()}`);
  state.textContent = `${data.items.length}件`;
  renderProductGrid(gridRoot, data.items);
}

async function loadCatalogSearch(queryText) {
  const state = document.getElementById("catalogSearchState");
  const gridRoot = document.getElementById("catalogSearchGrid");
  const title = document.getElementById("catalogSearchTitle");
  setCatalogSearchInputs(queryText || "");

  if (title) {
    title.textContent = queryText ? "検索結果" : "類似検索";
  }

  if (!queryText) {
    state.textContent = "";
    gridRoot.innerHTML = "";
    const empty = document.createElement("div");
    empty.className = "catalog-empty";
    empty.textContent = "キーワードを入力して、意味的に近い商品を探しましょう。";
    gridRoot.appendChild(empty);
    return;
  }

  const validationError = validateCatalogQuery(queryText);
  if (validationError) {
    state.textContent = validationError;
    gridRoot.innerHTML = "";
    return;
  }

  state.textContent = "検索中...";
  gridRoot.innerHTML = "";

  try {
    const data = await runSimilaritySearch({ type: "text", text: queryText });
    if (!data.items.length) {
      state.textContent = "類似する商品が見つかりませんでした。";
      const empty = document.createElement("div");
      empty.className = "catalog-empty";
      empty.textContent = "別のキーワードでお試しください。";
      gridRoot.appendChild(empty);
      return;
    }
    state.textContent = `「${queryText}」の検索結果 ${data.items.length}件`;
    renderProductGrid(gridRoot, data.items);
  } catch (err) {
    state.textContent = `エラー: ${err.message}`;
  }
}

async function loadCatalogProduct(productId) {
  const root = document.getElementById("catalogProductRoot");
  const similarState = document.getElementById("catalogSimilarState");
  const similarGrid = document.getElementById("catalogSimilarGrid");
  root.innerHTML = "読込中...";
  similarState.textContent = "";
  similarGrid.innerHTML = "";

  await ensureCatalogCategories();

  try {
    const product = await api(`/api/products/${productId}`);
    root.innerHTML = "";

    const detail = document.createElement("div");
    detail.className = "product-detail";

    const media = document.createElement("div");
    media.className = "product-detail-media";
    media.appendChild(productImageMarkup(product, "product-image"));

    const info = document.createElement("div");
    info.className = "product-detail-info";

    const title = document.createElement("h1");
    title.textContent = product.name;

    const meta = document.createElement("div");
    meta.className = "product-detail-meta";
    meta.textContent = `${displayCategory(product)} / ${product.productCode}`;

    const price = document.createElement("div");
    price.className = "product-detail-price";
    price.textContent = yen(product.price);

    const description = document.createElement("div");
    description.className = "product-detail-description";
    description.textContent = product.description || "説明はありません。";

    info.appendChild(title);
    info.appendChild(meta);
    info.appendChild(price);
    info.appendChild(description);
    detail.appendChild(media);
    detail.appendChild(info);
    root.appendChild(detail);

    if (product.embeddingStatus !== "embedded") {
      similarState.textContent = "類似商品は準備中です（Embedding 未生成）。";
      return;
    }

    similarState.textContent = "類似商品を読込中...";
    try {
      const data = await runSimilaritySearch({ type: "product", productId: Number(productId) });
      if (!data.items.length) {
        similarState.textContent = "類似商品が見つかりませんでした。";
        return;
      }
      similarState.textContent = "";
      renderProductGrid(similarGrid, data.items);
    } catch (err) {
      similarState.textContent = `類似商品の取得エラー: ${err.message}`;
    }
  } catch (err) {
    root.innerHTML = "";
    const empty = document.createElement("div");
    empty.className = "catalog-empty";
    empty.textContent = err.message.includes("404") ? "商品が見つかりません。" : `エラー: ${err.message}`;
    root.appendChild(empty);
  }
}

function updateCatalogNav(route) {
  document.querySelectorAll("[data-catalog-nav]").forEach((el) => {
    const nav = el.getAttribute("data-catalog-nav");
    el.classList.toggle("active", nav === "home" && route.view === "home");
  });
}

function submitCatalogSearch(event) {
  event.preventDefault();
  const query = getCatalogSearchInputValue();
  navigate(buildCatalogSearchHash(query));
}

function bindCatalogEvents() {
  document.querySelectorAll("[data-catalog-search-form]").forEach((form) => {
    form.addEventListener("submit", submitCatalogSearch);
  });
  document.querySelectorAll('nav.catalog-nav > a[data-catalog-nav="search"]').forEach((el) => el.remove());
}

async function renderCatalogRoute(route) {
  updateCatalogNav(route);
  document.querySelectorAll("[data-catalog-view]").forEach((el) => {
    el.classList.toggle("active", el.getAttribute("data-catalog-view") === route.view);
  });

  if (route.view === "home") {
    document.title = "Vector Search Store";
    await loadCatalogHome(route.query.category || "");
  } else if (route.view === "search") {
    document.title = "類似検索 | Vector Search Store";
    await loadCatalogSearch(route.query.q || "");
  } else if (route.view === "product") {
    document.title = "商品詳細 | Vector Search Store";
    await loadCatalogProduct(route.params.id);
  }
}

bindCatalogEvents();
