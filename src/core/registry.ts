import type { CloudPlatform } from "./types.js";
import type { CloudProvider } from "../providers/types.js";

export class ProviderRegistry {
  private providers = new Map<CloudPlatform, CloudProvider>();

  register(provider: CloudProvider): void {
    this.providers.set(provider.platform, provider);
  }

  get(platform: CloudPlatform): CloudProvider {
    const provider = this.providers.get(platform);
    if (!provider) {
      throw new Error(
        `No provider registered for platform "${platform}". Available: ${[...this.providers.keys()].join(", ") || "(none)"}`,
      );
    }
    return provider;
  }

  list(): CloudProvider[] {
    return [...this.providers.values()];
  }
}
