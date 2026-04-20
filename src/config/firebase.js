const fs = require("fs");
const admin = require("firebase-admin");
const env = require("./env");

let initialized = false;

function readServiceAccount() {
  if (env.firebaseServiceAccountBase64) {
    const raw = Buffer.from(env.firebaseServiceAccountBase64, "base64").toString("utf8");
    return JSON.parse(raw);
  }

  if (env.firebaseServiceAccountPath && fs.existsSync(env.firebaseServiceAccountPath)) {
    return JSON.parse(fs.readFileSync(env.firebaseServiceAccountPath, "utf8"));
  }

  return null;
}

function initFirebase() {
  if (initialized || admin.apps.length) {
    initialized = true;
    return admin;
  }

  const serviceAccount = readServiceAccount();

  if (!serviceAccount) {
    console.warn("Firebase service account not configured. FCM sends will be skipped.");
    return null;
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  initialized = true;
  console.log("Firebase Admin initialized");
  return admin;
}

function getFirebaseMessaging() {
  const firebase = initFirebase();
  return firebase ? firebase.messaging() : null;
}

module.exports = {
  initFirebase,
  getFirebaseMessaging
};

