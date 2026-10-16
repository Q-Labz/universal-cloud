import type {
  CloudPlatform,
  DesiredResource,
  ManagedResource,
  ResourceKind,
} from "../core/types.js";

export interface ProviderCapabilities {
  platform: CloudPlatform;
  supportedKinds: ResourceKind[];
  /** When false, the adapter only simulates API calls (safe default). */
  liveModeAvailable: boolean;
}

export interface ApplyOptions {
  dryRun: boolean;
}

export interface ApplyResult {
  resource: ManagedResource;
  message: string;
}

/**
 * Every cloud (GCP, AWS, Azure, …) implements this contract.
 * The control plane never talks to cloud SDKs directly — only through adapters.
 */
export interface CloudProvider {
  readonly platform: CloudPlatform;
  capabilities(): ProviderCapabilities;
  apply(desired: DesiredResource, options: ApplyOptions): Promise<ApplyResult>;
  destroy(resource: ManagedResource, options: ApplyOptions): Promise<ApplyResult>;
  get(resource: ManagedResource): Promise<ManagedResource>;
  list(tenancy: string, region?: string): Promise<ManagedResource[]>;
}
