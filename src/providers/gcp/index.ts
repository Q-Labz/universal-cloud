import type {
  DesiredResource,
  ManagedResource,
  ResourceKind,
} from "../../core/types.js";
import { newId, nowIso } from "../../core/ids.js";
import type {
  ApplyOptions,
  ApplyResult,
  CloudProvider,
  ProviderCapabilities,
} from "../types.js";
import { GCP_KIND_MAP, planGcpResource } from "./mapper.js";

const SUPPORTED: ResourceKind[] = [
  "compute.instance",
  "storage.bucket",
  "network.vpc",
  "network.subnet",
  "database.instance",
  "kubernetes.cluster",
];

/**
 * Google Cloud Platform adapter.
 *
 * Default mode is dry-run / simulated so demos and CI never touch a real project.
 * Set UNIVERSAL_CLOUD_LIVE=1 and provide Application Default Credentials to enable
 * live calls (wire your preferred GCP client in `executeLive`).
 */
export class GcpProvider implements CloudProvider {
  readonly platform = "gcp" as const;

  capabilities(): ProviderCapabilities {
    return {
      platform: this.platform,
      supportedKinds: SUPPORTED,
      liveModeAvailable: process.env.UNIVERSAL_CLOUD_LIVE === "1",
    };
  }

  async apply(
    desired: DesiredResource,
    options: ApplyOptions,
  ): Promise<ApplyResult> {
    this.assertSupported(desired.kind);
    const plan = planGcpResource(desired);
    const timestamp = nowIso();
    const providerId = `gcp://${desired.tenancy}/${desired.kind}/${desired.name}`;

    if (!options.dryRun && this.capabilities().liveModeAvailable) {
      await this.executeLive(plan);
    }

    const resource: ManagedResource = {
      ...desired,
      id: newId("res"),
      status: options.dryRun ? "pending" : "ready",
      providerId,
      endpoints: this.endpointsFor(desired, providerId),
      createdAt: timestamp,
      updatedAt: timestamp,
      labels: desired.labels,
      spec: {
        ...desired.spec,
        gcpNativeType: GCP_KIND_MAP[desired.kind],
        plannedRequest: plan,
      },
    };

    return {
      resource,
      message: options.dryRun
        ? `Dry-run: would create GCP ${GCP_KIND_MAP[desired.kind]} via ${plan.method} ${plan.path}`
        : `Applied GCP ${GCP_KIND_MAP[desired.kind]} ${desired.name}`,
    };
  }

  async destroy(
    resource: ManagedResource,
    options: ApplyOptions,
  ): Promise<ApplyResult> {
    this.assertSupported(resource.kind);
    const plan = planGcpResource(resource);

    if (!options.dryRun && this.capabilities().liveModeAvailable) {
      await this.executeLive({ ...plan, method: "DELETE" });
    }

    return {
      resource: {
        ...resource,
        status: options.dryRun ? "deleting" : "unknown",
        updatedAt: nowIso(),
      },
      message: options.dryRun
        ? `Dry-run: would delete GCP ${resource.providerId ?? resource.name}`
        : `Deleted GCP ${resource.providerId ?? resource.name}`,
    };
  }

  async get(resource: ManagedResource): Promise<ManagedResource> {
    return { ...resource, status: resource.status || "unknown", updatedAt: nowIso() };
  }

  async list(tenancy: string, region?: string): Promise<ManagedResource[]> {
    // Live inventory listing belongs here (Compute AggregatedList, etc.).
    // Until credentials are configured, return empty — the control-plane store is source of truth.
    void tenancy;
    void region;
    return [];
  }

  private assertSupported(kind: ResourceKind): void {
    if (!SUPPORTED.includes(kind)) {
      throw new Error(`GCP adapter does not support kind "${kind}"`);
    }
  }

  private endpointsFor(
    desired: DesiredResource,
    providerId: string,
  ): Record<string, string> {
    if (desired.kind === "storage.bucket") {
      return {
        console: `https://console.cloud.google.com/storage/browser/${desired.name}`,
        gs: `gs://${desired.name}`,
      };
    }
    if (desired.kind === "compute.instance") {
      return {
        console: `https://console.cloud.google.com/compute/instancesDetail/zones/${String(desired.spec.zone ?? desired.region)}/instances/${desired.name}?project=${desired.tenancy}`,
        providerId,
      };
    }
    return { providerId };
  }

  /**
   * Hook for real GCP API execution.
   * Replace with @google-cloud/* clients or REST + google-auth-library.
   */
  private async executeLive(plan: {
    method: string;
    path: string;
    body: Record<string, unknown>;
  }): Promise<void> {
    throw new Error(
      `Live GCP mode is enabled but no SDK client is wired yet. Planned ${plan.method} ${plan.path}. ` +
        "Install @google-cloud/compute (or related clients) and implement executeLive, or keep dryRun=true.",
    );
  }
}
