let adminLoaded = {
  categories: false,
  dashboard: false,
  products: false,
  search: false,
  operations: false,
};

let currentJobId = null;
let pollTimer = null;
let pollCount = 0;
const MAX_POLL = 200;

async function loadSummary() {
  const root = document.getElementById("summary");
  root.innerHTML = "";
  try {
    const data = await api("/api/dashboard/summary");
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
  } catch (err) {
    const msg = document.createElement("div");
    msg.className = "admin-state";
    msg.textContent = `サマリー取得エラー: ${err.message}`;
    root.appendChild(msg);
  }
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

async function ensureAdminCategories() {
  if (adminLoaded.categories) return;
  const items = await loadCategoryMeta();
  fillCategorySelect("productCategory", items);
  fillCategorySelect("searchCategory", items);
  adminLoaded.categories = true;
}

async function loadProducts() {
  const state = document.getElementById("productsState");
  const tbody = document.querySelector("#productsTable tbody");
  state.textContent = "読込中...";
  tbody.innerHTML = "";

  try {
    const q = document.getElementById("productQuery").value.trim();
    const embeddingStatus = document.getElementById("embeddingStatus").value;
    const category = document.getElementById("productCategory").value;
    const params = new URLSearchParams();
    if (q) params.set("q", q);
    if (embeddingStatus) params.set("embeddingStatus", embeddingStatus);
    if (category) params.set("category", category);
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
      tr.appendChild(td(displayCategory(item)));
      tr.appendChild(td(yen(item.price)));
      tr.appendChild(td(item.embeddingStatus));
      tbody.appendChild(tr);
    });
  } catch (err) {
    state.textContent = `エラー: ${err.message}`;
  }
}

async function runAdminSearch() {
  const state = document.getElementById("searchState");
  const tbody = document.querySelector("#searchTable tbody");
  state.textContent = "検索中...";
  tbody.innerHTML = "";

  try {
    const type = document.getElementById("queryType").value;
    const queryValue = document.getElementById("queryValue").value.trim();
    const topK = Number(document.getElementById("topK").value || 10);
    const scoreThreshold = Number(document.getElementById("threshold").value || 0);

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
    const category = document.getElementById("searchCategory").value;
    if (category) payload.category = category;
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
      tr.appendChild(td(displayCategory(item)));
      tbody.appendChild(tr);
    });
  } catch (err) {
    state.textContent = `エラー: ${err.message}`;
  }
}

async function loadJobFailures(jobId) {
  const table = document.getElementById("jobFailuresTable");
  const tbody = document.querySelector("#jobFailuresTable tbody");
  const state = document.getElementById("jobFailuresState");
  tbody.innerHTML = "";

  try {
    const data = await api(`/api/embeddings/failures?jobId=${encodeURIComponent(jobId)}`);
    if (!data.items.length) {
      table.hidden = true;
      state.textContent = "";
      return;
    }
    table.hidden = false;
    state.textContent = `失敗 ${data.items.length} 件`;
    data.items.forEach((item) => {
      const tr = document.createElement("tr");
      tr.appendChild(td(String(item.productId)));
      tr.appendChild(td(item.productCode));
      tr.appendChild(td(item.reason));
      tbody.appendChild(tr);
    });
  } catch (err) {
    table.hidden = true;
    state.textContent = `失敗一覧の取得エラー: ${err.message}`;
  }
}

function clearJobFailures() {
  document.getElementById("jobFailuresTable").hidden = true;
  document.querySelector("#jobFailuresTable tbody").innerHTML = "";
  document.getElementById("jobFailuresState").textContent = "";
}

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
      adminLoaded.dashboard = false;
      adminLoaded.products = false;
      await loadSummary();
      await loadProducts();
      if (job.failCount > 0) {
        await loadJobFailures(currentJobId);
      } else {
        clearJobFailures();
      }
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
  clearJobFailures();
  document.getElementById("jobState").textContent = `job開始: ${currentJobId}`;
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(pollJob, 1500);
}

function bindAdminEvents() {
  const loadProductsBtn = document.getElementById("loadProductsBtn");
  const runSearchBtn = document.getElementById("runSearchBtn");
  const startJobBtn = document.getElementById("startJobBtn");

  loadProductsBtn.addEventListener("click", () => {
    withButton(loadProductsBtn, loadProducts);
  });
  runSearchBtn.addEventListener("click", () => {
    withButton(runSearchBtn, runAdminSearch);
  });
  startJobBtn.addEventListener("click", () => {
    withButton(startJobBtn, () =>
      startEmbeddingJob().catch((err) => {
        document.getElementById("jobState").textContent = `エラー: ${err.message}`;
      })
    );
  });
}

async function loadAdminRouteData(view) {
  if (view === "dashboard" || view === "products" || view === "search") {
    await ensureAdminCategories();
  }
  if (adminLoaded[view]) return;

  if (view === "dashboard") {
    await loadSummary();
    await loadHealth();
  } else if (view === "products") {
    await loadProducts();
  }
  adminLoaded[view] = true;
}

async function renderAdminRoute(route) {
  document.querySelectorAll("[data-admin-view]").forEach((el) => {
    el.classList.toggle("active", el.getAttribute("data-admin-view") === route.view);
  });
  document.querySelectorAll("[data-admin-nav]").forEach((el) => {
    const href = el.getAttribute("href") || "";
    el.classList.toggle("active", href === `#/admin/${route.view}`);
  });

  const titles = {
    dashboard: "ダッシュボード",
    products: "商品管理",
    search: "類似検索",
    operations: "Embedding運用",
  };
  document.title = `${titles[route.view] || "管理画面"} | Vector Search 管理画面`;
  await loadAdminRouteData(route.view);
}

bindAdminEvents();
