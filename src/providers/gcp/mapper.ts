import type { DesiredResource, ResourceKind } from "../../core/types.js";

/** Maps universal kinds → Google Cloud native resource type names. */
export const GCP_KIND_MAP: Record<ResourceKind, string> = {
  "compute.instance": "compute.googleapis.com/Instance",
  "storage.bucket": "storage.googleapis.com/Bucket",
  "network.vpc": "compute.googleapis.com/Network",
  "network.subnet": "compute.googleapis.com/Subnetwork",
  "database.instance": "sqladmin.googleapis.com/Instance",
  "kubernetes.cluster": "container.googleapis.com/Cluster",
};

export interface GcpNativePlan {
  api: string;
  method: string;
  path: string;
  body: Record<string, unknown>;
}

/**
 * Translate a desired resource into a GCP REST-shaped plan.
 * Live mode can later POST this through google-auth + fetch / official SDKs.
 */
export function planGcpResource(desired: DesiredResource): GcpNativePlan {
  const project = desired.tenancy;
  const zoneOrRegion = String(desired.spec.zone ?? desired.region);
  const machineType = String(desired.spec.machineType ?? "e2-medium");
  const image = String(
    desired.spec.image ??
      "projects/debian-cloud/global/images/family/debian-12",
  );

  switch (desired.kind) {
    case "compute.instance":
      return {
        api: "compute",
        method: "POST",
        path: `/compute/v1/projects/${project}/zones/${zoneOrRegion}/instances`,
        body: {
          name: desired.name,
          machineType: `zones/${zoneOrRegion}/machineTypes/${machineType}`,
          disks: [
            {
              boot: true,
              autoDelete: true,
              initializeParams: { sourceImage: image },
            },
          ],
          networkInterfaces: [
            {
              network: String(desired.spec.network ?? "global/networks/default"),
              accessConfigs: [{ name: "External NAT", type: "ONE_TO_ONE_NAT" }],
            },
          ],
          labels: desired.labels,
        },
      };
    case "storage.bucket":
      return {
        api: "storage",
        method: "POST",
        path: `/storage/v1/b?project=${project}`,
        body: {
          name: desired.name,
          location: desired.region,
          storageClass: String(desired.spec.storageClass ?? "STANDARD"),
          labels: desired.labels,
        },
      };
    case "network.vpc":
      return {
        api: "compute",
        method: "POST",
        path: `/compute/v1/projects/${project}/global/networks`,
        body: {
          name: desired.name,
          autoCreateSubnetworks: Boolean(
            desired.spec.autoCreateSubnetworks ?? false,
          ),
          description: String(desired.spec.description ?? ""),
        },
      };
    case "network.subnet":
      return {
        api: "compute",
        method: "POST",
        path: `/compute/v1/projects/${project}/regions/${desired.region}/subnetworks`,
        body: {
          name: desired.name,
          network: String(desired.spec.network),
          ipCidrRange: String(desired.spec.cidr ?? "10.0.0.0/24"),
          region: desired.region,
        },
      };
    case "database.instance":
      return {
        api: "sqladmin",
        method: "POST",
        path: `/sql/v1beta4/projects/${project}/instances`,
        body: {
          name: desired.name,
          databaseVersion: String(desired.spec.engine ?? "POSTGRES_15"),
          region: desired.region,
          settings: {
            tier: String(desired.spec.tier ?? "db-f1-micro"),
            userLabels: desired.labels,
          },
        },
      };
    case "kubernetes.cluster":
      return {
        api: "container",
        method: "POST",
        path: `/v1/projects/${project}/locations/${desired.region}/clusters`,
        body: {
          cluster: {
            name: desired.name,
            initialNodeCount: Number(desired.spec.nodeCount ?? 3),
            nodeConfig: {
              machineType: String(desired.spec.machineType ?? "e2-medium"),
            },
            resourceLabels: desired.labels,
          },
        },
      };
    default: {
      const _exhaustive: never = desired.kind;
      throw new Error(`Unsupported GCP kind: ${_exhaustive}`);
    }
  }
}
