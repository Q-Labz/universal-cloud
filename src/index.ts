import { serve } from "@hono/node-server";
import { createApp } from "./api/server.js";
import { createControlPlane } from "./bootstrap.js";

const port = Number(process.env.PORT ?? 8787);
const plane = createControlPlane();
const app = createApp(plane);

serve({ fetch: app.fetch, port }, (info) => {
  console.log(`universal-cloud listening on http://localhost:${info.port}`);
  console.log("Providers:", plane.capabilities().map((p) => p.platform).join(", "));
});
