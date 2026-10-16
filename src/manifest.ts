import { readFileSync } from "node:fs";
import { parse as parseYaml } from "yaml";
import { ManifestSchema, type Manifest } from "./core/types.js";

export function loadManifest(path: string): Manifest {
  const raw = readFileSync(path, "utf8");
  const data = path.endsWith(".json") ? JSON.parse(raw) : parseYaml(raw);
  return ManifestSchema.parse(data);
}
