const env = require("../config/env");

function buildShopUrl(slug) {
  return `${env.appBaseUrl.replace(/\/$/, "")}/shop/${slug}`;
}

module.exports = buildShopUrl;

