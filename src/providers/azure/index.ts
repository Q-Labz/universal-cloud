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

const AZURE_KIND_MAP: Record<ResourceKind, string> = {
  "compute.instance": "Microsoft.Compute/virtualMachines",
  "storage.bucket": "Microsoft.Storage/storageAccounts",
  "network.vpc": "Microsoft.Network/virtualNetworks",
  "network.subnet": "Microsoft.Network/virtualNetworks/subnets",
  "database.instance": "Microsoft.DBforPostgreSQL/flexibleServers",
  "kubernetes.cluster": "Microsoft.ContainerService/managedClusters",
};

/** Azure adapter stub — implement with @azure/arm-* when needed. */
export class AzureProvider implements CloudProvider {
  readonly platform = "azure" as const;

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
      providerId: `azure://${desired.tenancy}/${desired.kind}/${desired.name}`,
      endpoints: {},
      createdAt: timestamp,
      updatedAt: timestamp,
      spec: {
        ...desired.spec,
        azureNativeType: AZURE_KIND_MAP[desired.kind],
      },
    };
    return {
      resource,
      message: options.dryRun
        ? `Dry-run: would create Azure ${AZURE_KIND_MAP[desired.kind]} ${desired.name}`
        : `Applied Azure ${AZURE_KIND_MAP[desired.kind]} ${desired.name}`,
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
        ? `Dry-run: would delete Azure ${resource.name}`
        : `Deleted Azure ${resource.name}`,
    };
  }

  async get(resource: ManagedResource): Promise<ManagedResource> {
    return resource;
  }

  async list(): Promise<ManagedResource[]> {
    return [];
  }
}
