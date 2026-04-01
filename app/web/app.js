// APIリクエスト（タイムアウト30秒付き）
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

// テキストセルを安全に生成（XSS対策）
function td(text) {
  const el = document.createElement("td");
  el.textContent = text ?? "-";
  return el;
}

// ボタンを非活性にして非同期処理を実行（多重押し防止）
async function withButton(btn, fn) {
  btn.disabled = true;
  try {
    await fn();
  } finally {
    btn.disabled = false;
  }
}

async function loadSummary() {
  const data = await api("/api/dashboard/summary");
  const root = document.getElementById("summary");
  root.innerHTML = "";
  [
    ["商品総数", data.totalProducts],
    ["Embedding生成済み", data.embeddedProducts],
    ["未生成", data.missingEmbeddings],
  ].forEach(([label, value]) => {
    const card = document.createElement("div");
    card.className = "kpi-card";
    const labelEl = document.createElement("div");
    labelEl.className = "label";
    labelEl.textContent = label;
    const valueEl = document.createElement("div");
    valueEl.className = "value";
    valueEl.textContent = value;
    card.appendChild(labelEl);
    card.appendChild(valueEl);
    root.appendChild(card);
  });
}

async function loadProducts() {
  const state = document.getElementById("productsState");
  const tbody = document.querySelector("#productsTable tbody");
  state.textContent = "読込中...";
  tbody.innerHTML = "";

  try {
    const q = document.getElementById("productQuery").value.trim();
    const embeddingStatus = document.getElementById("embeddingStatus").value;
    const params = new URLSearchParams();
    if (q) params.set("q", q);
    if (embeddingStatus) params.set("embeddingStatus", embeddingStatus);
    const data = await api(`/api/products?${params.toString()}`);
    if (!data.items.length) {
      state.textContent = "条件に一致する商品がありません。";
      return;
    }
    state.textContent = `${data.items.length}件表示`;
    data.items.forEach((item) => {
      const tr = document.createElement("tr");
      tr.appendChild(td(item.id));
      tr.appendChild(td(item.productCode));
      tr.appendChild(td(item.name));
      tr.appendChild(td(item.category));
      tr.appendChild(td(yen(item.price)));
      tr.appendChild(td(item.embeddingStatus));
      tbody.appendChild(tr);
    });
  } catch (err) {
    state.textContent = `エラー: ${err.message}`;
  }
}

async function runSearch() {
  const state = document.getElementById("searchState");
  const tbody = document.querySelector("#searchTable tbody");
  state.textContent = "検索中...";
  tbody.innerHTML = "";

  try {
    const type = document.getElementById("queryType").value;
    const queryValue = document.getElementById("queryValue").value.trim();
    const topK = Number(document.getElementById("topK").value || 10);
    const scoreThreshold = Number(document.getElementById("threshold").value || 0);

    // 入力バリデーション
    if (!queryValue) {
      state.textContent = "エラー: 検索クエリを入力してください。";
      return;
    }
    if (queryValue.length > 500) {
      state.textContent = "エラー: 検索クエリは500文字以内で入力してください。";
      return;
    }
    if (!Number.isInteger(topK) || topK < 1 || topK > 50) {
      state.textContent = "エラー: 取得件数は1〜50の整数で入力してください。";
      return;
    }
    if (isNaN(scoreThreshold) || scoreThreshold < -1 || scoreThreshold > 1) {
      state.textContent = "エラー: 閾値は-1〜1の範囲で入力してください。";
      return;
    }

    const payload = { type, topK, scoreThreshold };
    if (type === "product") payload.productId = Number(queryValue);
    else payload.text = queryValue;

    const data = await api("/api/similarity/search", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    if (!data.items.length) {
      state.textContent = "結果がありません。閾値を下げて再検索してください。";
      return;
    }
    state.textContent = `${data.items.length}件`;
    data.items.forEach((item) => {
      const tr = document.createElement("tr");
      tr.appendChild(td(item.rank));
      tr.appendChild(td(item.score.toFixed(4)));
      tr.appendChild(td(item.productCode));
      tr.appendChild(td(item.name));
      tr.appendChild(td(item.category));
      tbody.appendChild(tr);
    });
  } catch (err) {
    state.textContent = `エラー: ${err.message}`;
  }
}

let currentJobId = null;
let pollTimer = null;
let pollCount = 0;
const MAX_POLL = 200; // 最大5分 (1.5秒 × 200回)

async function pollJob() {
  if (!currentJobId) return;

  pollCount++;
  if (pollCount > MAX_POLL) {
    clearInterval(pollTimer);
    pollTimer = null;
    document.getElementById("jobState").textContent = "タイムアウト: ジョブの完了を確認できませんでした。";
    return;
  }

  try {
    const job = await api(`/api/embeddings/jobs/${currentJobId}`);
    document.getElementById("jobState").textContent =
      `status=${job.status}, progress=${Math.round(job.progress * 100)}%, success=${job.successCount}, fail=${job.failCount}`;
    if (job.status === "done" || job.status === "error") {
      clearInterval(pollTimer);
      pollTimer = null;
      await loadSummary();
      await loadProducts();
    }
  } catch (err) {
    document.getElementById("jobState").textContent = `エラー: ${err.message}`;
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

async function startEmbeddingJob() {
  const mode = document.getElementById("jobMode").value;
  const result = await api("/api/embeddings/jobs", {
    method: "POST",
    body: JSON.stringify({ mode }),
  });
  currentJobId = result.jobId;
  pollCount = 0;
  document.getElementById("jobState").textContent = `job開始: ${currentJobId}`;
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(pollJob, 1500);
}

async function loadHealth() {
  try {
    const data = await api("/api/system/health");
    document.getElementById("health").textContent =
      `API=${data.api}, DB=${data.db}, pgvector=${data.pgvector}, checkedAt=${data.checkedAt}`;
  } catch (err) {
    document.getElementById("health").textContent = `エラー: ${err.message}`;
  }
}

const loadProductsBtn = document.getElementById("loadProductsBtn");
const runSearchBtn = document.getElementById("runSearchBtn");
const startJobBtn = document.getElementById("startJobBtn");

loadProductsBtn.addEventListener("click", () => {
  withButton(loadProductsBtn, loadProducts);
});
runSearchBtn.addEventListener("click", () => {
  withButton(runSearchBtn, runSearch);
});
startJobBtn.addEventListener("click", () => {
  withButton(startJobBtn, () =>
    startEmbeddingJob().catch((err) => {
      document.getElementById("jobState").textContent = `エラー: ${err.message}`;
    })
  );
});

const loadedViews = {
  dashboard: false,
  products: false,
  search: false,
  operations: false,
};

function getRoute() {
  const raw = window.location.hash.replace("#/", "").trim();
  if (["dashboard", "products", "search", "operations"].includes(raw)) {
    return raw;
  }
  return "dashboard";
}

async function loadRouteData(route) {
  if (loadedViews[route]) return;
  if (route === "dashboard") {
    await loadSummary();
    await loadHealth();
  } else if (route === "products") {
    await loadProducts();
  }
  loadedViews[route] = true;
}

async function renderRoute() {
  const route = getRoute();
  document.querySelectorAll("[data-route-view]").forEach((el) => {
    el.classList.toggle("active", el.getAttribute("data-route-view") === route);
  });
  document.querySelectorAll("[data-route-link]").forEach((el) => {
    const href = el.getAttribute("href") || "";
    el.classList.toggle("active", href === `#/${route}`);
  });
  await loadRouteData(route);
}

window.addEventListener("hashchange", () => {
  renderRoute().catch((err) => console.error("ルート描画エラー:", err));
});

if (!window.location.hash) {
  window.location.hash = "#/dashboard";
}
renderRoute().catch((err) => console.error("初期描画エラー:", err));
