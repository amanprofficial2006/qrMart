const fs = require("fs");
const path = require("path");

const DEFAULT_GOOGLE_CLIENT_IDS = [
  "326409235411-m2v9butg0bib4vhkl3sb8vdqat6hghsu.apps.googleusercontent.com",
  "326409235411-p0847q8e0b6t10115pnr1nc6jh4l0u5v.apps.googleusercontent.com"
];
const defaultSecretFiles = [
  path.resolve(
    process.cwd(),
    "frontend",
    "client_secret_326409235411-m2v9butg0bib4vhkl3sb8vdqat6hghsu.apps.googleusercontent.com.json"
  ),
  path.resolve(
    process.cwd(),
    "owner_app",
    "client_secret_326409235411-p0847q8e0b6t10115pnr1nc6jh4l0u5v.apps.googleusercontent.com.json"
  )
];

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

function normalizeClientIds(value) {
  return String(value || "")
    .split(",")
    .map(normalizeClientId)
    .filter(Boolean);
}

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

const configuredSecretFile = process.env.GOOGLE_CLIENT_SECRET_FILE
  ? path.resolve(process.cwd(), process.env.GOOGLE_CLIENT_SECRET_FILE)
  : "";

const googleClientIds = unique([
  ...normalizeClientIds(process.env.GOOGLE_CLIENT_IDS),
  normalizeClientId(process.env.GOOGLE_CLIENT_ID),
  normalizeClientId(clientIdFromFile(configuredSecretFile)),
  ...defaultSecretFiles.map((filePath) => normalizeClientId(clientIdFromFile(filePath))),
  ...DEFAULT_GOOGLE_CLIENT_IDS.map(normalizeClientId)
]);

const googleClientId = googleClientIds[0] || "";

module.exports = {
  googleClientId,
  googleClientIds
};
