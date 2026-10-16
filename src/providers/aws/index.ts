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

const SUPPORTED: ResourceKind[] = [
  "compute.instance",
  "storage.bucket",
  "network.vpc",
  "network.subnet",
  "database.instance",
  "kubernetes.cluster",
];

const AWS_KIND_MAP: Record<ResourceKind, string> = {
  "compute.instance": "ec2:instance",
  "storage.bucket": "s3:bucket",
  "network.vpc": "ec2:vpc",
  "network.subnet": "ec2:subnet",
  "database.instance": "rds:db",
  "kubernetes.cluster": "eks:cluster",
};

/** AWS adapter stub — same contract as GCP; wire AWS SDK v3 when a client needs it. */
export class AwsProvider implements CloudProvider {
  readonly platform = "aws" as const;

  capabilities(): ProviderCapabilities {
    return {
      platform: this.platform,
      supportedKinds: SUPPORTED,
      liveModeAvailable: false,
    };
  }

  async apply(
    desired: DesiredResource,
    options: ApplyOptions,
  ): Promise<ApplyResult> {
    const timestamp = nowIso();
    const resource: ManagedResource = {
      ...desired,
      id: newId("res"),
      status: options.dryRun ? "pending" : "ready",
      providerId: `aws://${desired.tenancy}/${desired.kind}/${desired.name}`,
      endpoints: {},
      createdAt: timestamp,
      updatedAt: timestamp,
      spec: {
        ...desired.spec,
        awsNativeType: AWS_KIND_MAP[desired.kind],
      },
    };
    return {
      resource,
      message: options.dryRun
        ? `Dry-run: would create AWS ${AWS_KIND_MAP[desired.kind]} ${desired.name}`
        : `Applied AWS ${AWS_KIND_MAP[desired.kind]} ${desired.name}`,
    };
  }

  async destroy(
    resource: ManagedResource,
    options: ApplyOptions,
  ): Promise<ApplyResult> {
    return {
      resource: {
        ...resource,
        status: options.dryRun ? "deleting" : "unknown",
        updatedAt: nowIso(),
      },
      message: options.dryRun
        ? `Dry-run: would delete AWS ${resource.name}`
        : `Deleted AWS ${resource.name}`,
    };
  }

  async get(resource: ManagedResource): Promise<ManagedResource> {
    return resource;
  }

  async list(): Promise<ManagedResource[]> {
    return [];
  }
}
