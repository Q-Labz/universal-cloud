import { Hono } from "hono";
import { cors } from "hono/cors";
import type { ControlPlane } from "../core/engine.js";
import {
  DesiredResourceSchema,
  ManifestSchema,
} from "../core/types.js";

export function createApp(plane: ControlPlane): Hono {
  const app = new Hono();
  app.use("*", cors());

  app.get("/health", (c) =>
    c.json({ ok: true, service: "universal-cloud", version: "0.1.0" }),
  );

  app.get("/v1/providers", (c) => c.json({ providers: plane.capabilities() }));

  app.get("/v1/resources", (c) => {
    const platform = c.req.query("platform") ?? undefined;
    const tenancy = c.req.query("tenancy") ?? undefined;
    return c.json({ resources: plane.listResources({ platform, tenancy }) });
  });

  app.get("/v1/resources/:id", (c) => {
    const resource = plane.getResource(c.req.param("id"));
    if (!resource) return c.json({ error: "not_found" }, 404);
    return c.json({ resource });
  });

  app.post("/v1/resources", async (c) => {
    const body = await c.req.json();
    const dryRun = c.req.query("dryRun") !== "false";
    const desired = DesiredResourceSchema.parse(body);
    const result = await plane.applyResource(desired, { dryRun });
    return c.json(result, 201);
  });

  app.post("/v1/stacks:apply", async (c) => {
    const body = await c.req.json();
    const dryRun = c.req.query("dryRun") !== "false";
    const manifest = ManifestSchema.parse(body);
    const result = await plane.applyStack(manifest, { dryRun });
    return c.json(result, 201);
  });

  app.delete("/v1/resources/:id", async (c) => {
    const dryRun = c.req.query("dryRun") !== "false";
    const result = await plane.destroyResource(c.req.param("id"), { dryRun });
    return c.json(result);
  });

  app.get("/v1/operations", (c) =>
    c.json({ operations: plane.listOperations() }),
  );

  app.get("/v1/operations/:id", (c) => {
    const operation = plane.getOperation(c.req.param("id"));
    if (!operation) return c.json({ error: "not_found" }, 404);
    return c.json({ operation });
  });

  app.onError((err, c) => {
    const message = err instanceof Error ? err.message : String(err);
    const status = message.includes("not found") ? 404 : 400;
    return c.json({ error: message }, status);
  });

  return app;
}
