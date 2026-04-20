const env = require("../config/env");

function normalizeBaseUrl(baseUrl = env.appBaseUrl) {
  const rawBaseUrl = String(baseUrl || env.appBaseUrl).trim();
  const parsed = new URL(rawBaseUrl);

  if (!["http:", "https:"].includes(parsed.protocol)) {
    throw new Error("Shop URL must use http or https");
  }

  const pathname = parsed.pathname === "/" ? "" : parsed.pathname.replace(/\/+$/, "");
  return `${parsed.origin}${pathname}`;
}

function buildShopUrl(slug, baseUrl) {
  return `${normalizeBaseUrl(baseUrl)}/shop/${slug}`;
}

module.exports = buildShopUrl;
