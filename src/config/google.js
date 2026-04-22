const fs = require("fs");
const path = require("path");

const DEFAULT_GOOGLE_CLIENT_ID = "326409235411-m2v9butg0bib4vhkl3sb8vdqat6hghsu.apps.googleusercontent.com";
const defaultSecretFile = path.resolve(
  process.cwd(),
  "frontend",
  "client_secret_326409235411-m2v9butg0bib4vhkl3sb8vdqat6hghsu.apps.googleusercontent.com.json"
);

function clientIdFromFile(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    return "";
  }

  try {
    const config = JSON.parse(fs.readFileSync(filePath, "utf8"));
    const appConfig = config.web || config.installed || config;
    return appConfig.client_id || "";
  } catch {
    return "";
  }
}

function normalizeClientId(value) {
  return String(value || "").trim();
}

const googleClientId =
  normalizeClientId(process.env.GOOGLE_CLIENT_ID) ||
  normalizeClientId(
    clientIdFromFile(process.env.GOOGLE_CLIENT_SECRET_FILE && path.resolve(process.cwd(), process.env.GOOGLE_CLIENT_SECRET_FILE))
  ) ||
  normalizeClientId(clientIdFromFile(defaultSecretFile)) ||
  DEFAULT_GOOGLE_CLIENT_ID;

module.exports = {
  googleClientId
};
