import { ControlPlane } from "./core/engine.js";
import { ProviderRegistry } from "./core/registry.js";
import { MemoryStore } from "./store/memory.js";
import { GcpProvider } from "./providers/gcp/index.js";
import { AwsProvider } from "./providers/aws/index.js";
import { AzureProvider } from "./providers/azure/index.js";

export function createControlPlane(): ControlPlane {
  const registry = new ProviderRegistry();
  registry.register(new GcpProvider());
  registry.register(new AwsProvider());
  registry.register(new AzureProvider());
  return new ControlPlane(registry, new MemoryStore());
}
