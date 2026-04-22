const fs = require("fs");
const path = require("path");

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

const googleClientId =
  process.env.GOOGLE_CLIENT_ID ||
  clientIdFromFile(process.env.GOOGLE_CLIENT_SECRET_FILE && path.resolve(process.cwd(), process.env.GOOGLE_CLIENT_SECRET_FILE)) ||
  clientIdFromFile(defaultSecretFile);

module.exports = {
  googleClientId
};
