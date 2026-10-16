import { z } from "zod";

/** Supported cloud platforms. Add new providers here, then implement CloudProvider. */
export const CloudPlatformSchema = z.enum(["gcp", "aws", "azure"]);
export type CloudPlatform = z.infer<typeof CloudPlatformSchema>;

/**
 * Normalized resource kinds every provider must map to.
 * Keep this list small and intentional — provider-specific extras go in `spec`.
 */
export const ResourceKindSchema = z.enum([
  "compute.instance",
  "storage.bucket",
  "network.vpc",
  "network.subnet",
  "database.instance",
  "kubernetes.cluster",
]);
export type ResourceKind = z.infer<typeof ResourceKindSchema>;

export const ResourceStatusSchema = z.enum([
  "pending",
  "creating",
  "ready",
  "updating",
  "deleting",
  "failed",
  "unknown",
]);
export type ResourceStatus = z.infer<typeof ResourceStatusSchema>;

export const DesiredResourceSchema = z.object({
  name: z.string().min(1).max(63),
  kind: ResourceKindSchema,
  platform: CloudPlatformSchema,
  region: z.string().min(1),
  /** Project / account / subscription identifier for the target cloud. */
  tenancy: z.string().min(1),
  labels: z.record(z.string()).default({}),
  /** Provider-agnostic intent. Adapters translate this into native APIs. */
  spec: z.record(z.unknown()).default({}),
});
export type DesiredResource = z.infer<typeof DesiredResourceSchema>;

export const ManagedResourceSchema = DesiredResourceSchema.extend({
  id: z.string(),
  status: ResourceStatusSchema,
  providerId: z.string().optional(),
  endpoints: z.record(z.string()).default({}),
  createdAt: z.string(),
  updatedAt: z.string(),
  lastError: z.string().optional(),
});
export type ManagedResource = z.infer<typeof ManagedResourceSchema>;

export const OperationTypeSchema = z.enum([
  "create",
  "update",
  "delete",
  "read",
  "list",
]);
export type OperationType = z.infer<typeof OperationTypeSchema>;

export const OperationSchema = z.object({
  id: z.string(),
  type: OperationTypeSchema,
  platform: CloudPlatformSchema,
  resourceId: z.string().optional(),
  status: z.enum(["queued", "running", "succeeded", "failed"]),
  dryRun: z.boolean().default(true),
  message: z.string().optional(),
  startedAt: z.string(),
  finishedAt: z.string().optional(),
});
export type Operation = z.infer<typeof OperationSchema>;

export const ManifestSchema = z.object({
  apiVersion: z.literal("universal-cloud/v1"),
  kind: z.literal("Stack"),
  metadata: z.object({
    name: z.string(),
    labels: z.record(z.string()).optional(),
  }),
  spec: z.object({
    resources: z.array(DesiredResourceSchema).min(1),
  }),
});
export type Manifest = z.infer<typeof ManifestSchema>;
