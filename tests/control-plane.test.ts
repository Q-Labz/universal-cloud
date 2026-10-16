import { describe, expect, it } from "vitest";
import { createControlPlane } from "../src/bootstrap.js";
import type { Manifest } from "../src/core/types.js";

const gcpManifest: Manifest = {
  apiVersion: "universal-cloud/v1",
  kind: "Stack",
  metadata: { name: "test-stack" },
  spec: {
    resources: [
      {
        name: "test-bucket",
        kind: "storage.bucket",
        platform: "gcp",
        region: "US",
        tenancy: "client-gcp-project",
        labels: { client: "acme" },
        spec: { storageClass: "STANDARD" },
      },
    ],
  },
};

describe("ControlPlane", () => {
  it("registers gcp, aws, and azure providers", () => {
    const plane = createControlPlane();
    const platforms = plane.capabilities().map((c) => c.platform).sort();
    expect(platforms).toEqual(["aws", "azure", "gcp"]);
  });

  it("dry-runs a GCP stack and tracks operations", async () => {
    const plane = createControlPlane();
    const result = await plane.applyStack(gcpManifest, { dryRun: true });

    expect(result.resources).toHaveLength(1);
    expect(result.resources[0]?.platform).toBe("gcp");
    expect(result.resources[0]?.status).toBe("pending");
    expect(result.operations[0]?.status).toBe("succeeded");
    expect(result.operations[0]?.dryRun).toBe(true);
    expect(result.operations[0]?.message).toMatch(/Dry-run/i);

    const listed = plane.listResources({ platform: "gcp" });
    expect(listed).toHaveLength(1);
    expect(listed[0]?.name).toBe("test-bucket");
  });

  it("applies mixed-cloud resources through one API", async () => {
    const plane = createControlPlane();
    const mixed: Manifest = {
      apiVersion: "universal-cloud/v1",
      kind: "Stack",
      metadata: { name: "mixed" },
      spec: {
        resources: [
          {
            name: "g-bucket",
            kind: "storage.bucket",
            platform: "gcp",
            region: "US",
            tenancy: "p1",
            labels: {},
            spec: {},
          },
          {
            name: "a-bucket",
            kind: "storage.bucket",
            platform: "aws",
            region: "us-east-1",
            tenancy: "123",
            labels: {},
            spec: {},
          },
        ],
      },
    };

    const result = await plane.applyStack(mixed, { dryRun: true });
    expect(result.resources.map((r) => r.platform).sort()).toEqual([
      "aws",
      "gcp",
    ]);
  });
});
