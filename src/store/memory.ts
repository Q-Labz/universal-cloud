import type { ManagedResource, Operation } from "../core/types.js";

/** In-memory store for local/dev. Swap for Postgres/Netlify DB in production. */
export class MemoryStore {
  private resources = new Map<string, ManagedResource>();
  private operations = new Map<string, Operation>();

  upsertResource(resource: ManagedResource): ManagedResource {
    this.resources.set(resource.id, resource);
    return resource;
  }

  getResource(id: string): ManagedResource | undefined {
    return this.resources.get(id);
  }

  findByName(
    platform: string,
    tenancy: string,
    name: string,
  ): ManagedResource | undefined {
    for (const resource of this.resources.values()) {
      if (
        resource.platform === platform &&
        resource.tenancy === tenancy &&
        resource.name === name
      ) {
        return resource;
      }
    }
    return undefined;
  }

  listResources(filter?: {
    platform?: string;
    tenancy?: string;
  }): ManagedResource[] {
    return [...this.resources.values()].filter((resource) => {
      if (filter?.platform && resource.platform !== filter.platform) return false;
      if (filter?.tenancy && resource.tenancy !== filter.tenancy) return false;
      return true;
    });
  }

  deleteResource(id: string): boolean {
    return this.resources.delete(id);
  }

  saveOperation(operation: Operation): Operation {
    this.operations.set(operation.id, operation);
    return operation;
  }

  getOperation(id: string): Operation | undefined {
    return this.operations.get(id);
  }

  listOperations(): Operation[] {
    return [...this.operations.values()].sort((a, b) =>
      b.startedAt.localeCompare(a.startedAt),
    );
  }
}
