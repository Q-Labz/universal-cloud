import { describe, expect, it } from "vitest";
import { planGcpResource } from "../src/providers/gcp/mapper.js";
import type { DesiredResource } from "../src/core/types.js";

const base: Omit<DesiredResource, "kind" | "name" | "spec"> = {
  platform: "gcp",
  region: "us-central1",
  tenancy: "demo-project",
  labels: { env: "test" },
};

describe("planGcpResource", () => {
  it("plans a compute instance for the project zone", () => {
    const plan = planGcpResource({
      ...base,
      name: "web-1",
      kind: "compute.instance",
      spec: { zone: "us-central1-a", machineType: "e2-small" },
    });

    expect(plan.method).toBe("POST");
    expect(plan.path).toContain("/projects/demo-project/zones/us-central1-a/instances");
    expect(plan.body.name).toBe("web-1");
    expect(String(plan.body.machineType)).toContain("e2-small");
  });

  it("plans a storage bucket", () => {
    const plan = planGcpResource({
      ...base,
      name: "demo-bucket",
      kind: "storage.bucket",
      region: "US",
      spec: {},
    });

    expect(plan.path).toContain("/storage/v1/b?project=demo-project");
    expect(plan.body.location).toBe("US");
  });
});
