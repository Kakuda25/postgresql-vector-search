async function renderApp() {
  const route = parseHash();

  if (route.redirect) {
    navigate(route.redirect);
    return;
  }

  const catalogApp = document.getElementById("catalogApp");
  const adminApp = document.getElementById("adminApp");
  const isCatalog = route.area === "catalog";

  catalogApp.classList.toggle("hidden", !isCatalog);
  adminApp.classList.toggle("hidden", isCatalog);

  try {
    if (isCatalog) {
      await renderCatalogRoute(route);
    } else {
      await renderAdminRoute(route);
    }
  } catch (err) {
    console.error("描画エラー:", err);
  }
}

window.addEventListener("hashchange", () => {
  renderApp().catch((err) => console.error("ルート描画エラー:", err));
});

if (!window.location.hash || window.location.hash === "#/" || window.location.hash === "#") {
  window.location.hash = "#/catalog";
} else {
  renderApp().catch((err) => console.error("初期描画エラー:", err));
}
