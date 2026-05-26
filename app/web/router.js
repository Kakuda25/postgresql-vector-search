const LEGACY_ADMIN_ROUTES = new Set(["dashboard", "products", "search", "operations"]);
const ADMIN_VIEWS = new Set(["dashboard", "products", "search", "operations"]);

function parseHash() {
  const raw = window.location.hash.replace(/^#/, "");
  if (!raw || raw === "/") {
    return { area: "catalog", view: "home", params: {}, query: {} };
  }

  const [pathPart, queryPart] = raw.split("?");
  const query = Object.fromEntries(new URLSearchParams(queryPart || ""));
  const parts = pathPart.replace(/^\//, "").split("/").filter(Boolean);

  if (parts[0] === "catalog") {
    if (parts[1] === "search") {
      return { area: "catalog", view: "search", params: {}, query };
    }
    if (parts[1] === "products" && parts[2]) {
      return { area: "catalog", view: "product", params: { id: parts[2] }, query };
    }
    return { area: "catalog", view: "home", params: {}, query };
  }

  if (parts[0] === "admin") {
    const view = parts[1] || "dashboard";
    if (ADMIN_VIEWS.has(view)) {
      return { area: "admin", view, params: {}, query };
    }
  }

  if (parts.length === 1 && LEGACY_ADMIN_ROUTES.has(parts[0])) {
    return { redirect: "#/catalog" };
  }

  return { redirect: "#/catalog" };
}

function navigate(hash) {
  if (window.location.hash !== hash) {
    window.location.hash = hash;
  }
}

function buildCatalogHomeHash(category) {
  if (!category) return "#/catalog";
  return `#/catalog?category=${encodeURIComponent(category)}`;
}

function buildCatalogSearchHash(queryText) {
  if (!queryText) return "#/catalog/search";
  return `#/catalog/search?q=${encodeURIComponent(queryText)}`;
}
