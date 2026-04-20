const http = require("http");
const app = require("./app");
const env = require("./config/env");
const connectDb = require("./config/db");
const { initFirebase } = require("./config/firebase");
const { initRealtime } = require("./services/realtime.service");

async function bootstrap() {
  await connectDb();
  initFirebase();

  const server = http.createServer(app);
  initRealtime(server);

  server.listen(env.port, () => {
    console.log(`qrMart API running on port ${env.port}`);
  });
}

bootstrap().catch((error) => {
  console.error("Failed to start server", error);
  process.exit(1);
});
