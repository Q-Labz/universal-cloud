import type {
  DesiredResource,
  ManagedResource,
  Manifest,
  Operation,
} from "./types.js";
import { ProviderRegistry } from "./registry.js";
import { MemoryStore } from "../store/memory.js";
import { newId, nowIso } from "./ids.js";

export interface ApplyStackOptions {
  dryRun: boolean;
}

export class ControlPlane {
  constructor(
    private readonly registry: ProviderRegistry,
    private readonly store: MemoryStore,
  ) {}

  capabilities() {
    return this.registry.list().map((provider) => provider.capabilities());
  }

  listResources(filter?: { platform?: string; tenancy?: string }) {
    return this.store.listResources(filter);
  }

  getResource(id: string) {
    return this.store.getResource(id);
  }

  listOperations() {
    return this.store.listOperations();
  }

  getOperation(id: string) {
    return this.store.getOperation(id);
  }

  async applyResource(
    desired: DesiredResource,
    options: ApplyStackOptions,
  ): Promise<{ resource: ManagedResource; operation: Operation }> {
    const provider = this.registry.get(desired.platform);
    const existing = this.store.findByName(
      desired.platform,
      desired.tenancy,
      desired.name,
    );

    const operation: Operation = {
      id: newId("op"),
      type: existing ? "update" : "create",
      platform: desired.platform,
      resourceId: existing?.id,
      status: "running",
      dryRun: options.dryRun,
      startedAt: nowIso(),
    };
    this.store.saveOperation(operation);

    try {
      const result = await provider.apply(desired, { dryRun: options.dryRun });
      const resource: ManagedResource = {
        ...result.resource,
        id: existing?.id ?? result.resource.id,
        createdAt: existing?.createdAt ?? result.resource.createdAt,
        updatedAt: nowIso(),
      };
      this.store.upsertResource(resource);

      const finished: Operation = {
        ...operation,
        resourceId: resource.id,
        status: "succeeded",
        message: result.message,
        finishedAt: nowIso(),
      };
      this.store.saveOperation(finished);
      return { resource, operation: finished };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      const failed: Operation = {
        ...operation,
        status: "failed",
        message,
        finishedAt: nowIso(),
      };
      this.store.saveOperation(failed);
      throw error;
    }
  }

  async applyStack(
    manifest: Manifest,
    options: ApplyStackOptions,
  ): Promise<{
    resources: ManagedResource[];
    operations: Operation[];
  }> {
    const resources: ManagedResource[] = [];
    const operations: Operation[] = [];

    for (const desired of manifest.spec.resources) {
      const result = await this.applyResource(desired, options);
      resources.push(result.resource);
      operations.push(result.operation);
    }

    return { resources, operations };
  }

  async destroyResource(
    id: string,
    options: ApplyStackOptions,
  ): Promise<{ resource: ManagedResource; operation: Operation }> {
    const existing = this.store.getResource(id);
    if (!existing) {
      throw new Error(`Resource not found: ${id}`);
    }

    const provider = this.registry.get(existing.platform);
    const operation: Operation = {
      id: newId("op"),
      type: "delete",
      platform: existing.platform,
      resourceId: existing.id,
      status: "running",
      dryRun: options.dryRun,
      startedAt: nowIso(),
    };
    this.store.saveOperation(operation);

    try {
      const result = await provider.destroy(existing, { dryRun: options.dryRun });
      if (!options.dryRun) {
        this.store.deleteResource(existing.id);
      } else {
        this.store.upsertResource({
          ...result.resource,
          status: "deleting",
          updatedAt: nowIso(),
        });
      }

      const finished: Operation = {
        ...operation,
        status: "succeeded",
        message: result.message,
        finishedAt: nowIso(),
      };
      this.store.saveOperation(finished);
      return { resource: result.resource, operation: finished };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      const failed: Operation = {
        ...operation,
        status: "failed",
        message,
        finishedAt: nowIso(),
      };
      this.store.saveOperation(failed);
      throw error;
    }
  }
}
