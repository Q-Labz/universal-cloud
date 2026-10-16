#!/usr/bin/env node
import { createControlPlane } from "./bootstrap.js";
import { loadManifest } from "./manifest.js";

function usage(): never {
  console.log(`universal-cloud (ucloud)

Usage:
  npm run cli -- providers
  npm run cli -- apply <manifest.yaml|json> [--live]
  npm run cli -- resources [--platform gcp|aws|azure]
  npm run cli -- destroy <resourceId> [--live]
  npm run cli -- operations

Notes:
  Default is dry-run (safe). Pass --live to mark operations as non-dry-run.
  GCP live API calls additionally require UNIVERSAL_CLOUD_LIVE=1 and credentials.
`);
  process.exit(1);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  if (args.length === 0) usage();

  const plane = createControlPlane();
  const cmd = args[0];

  switch (cmd) {
    case "providers": {
      console.log(JSON.stringify(plane.capabilities(), null, 2));
      return;
    }
    case "apply": {
      const path = args[1];
      if (!path) usage();
      const live = args.includes("--live");
      const manifest = loadManifest(path);
      const result = await plane.applyStack(manifest, { dryRun: !live });
      console.log(JSON.stringify(result, null, 2));
      return;
    }
    case "resources": {
      const platformIdx = args.indexOf("--platform");
      const platform =
        platformIdx >= 0 ? args[platformIdx + 1] : undefined;
      console.log(
        JSON.stringify(plane.listResources({ platform }), null, 2),
      );
      return;
    }
    case "destroy": {
      const id = args[1];
      if (!id) usage();
      const live = args.includes("--live");
      const result = await plane.destroyResource(id, { dryRun: !live });
      console.log(JSON.stringify(result, null, 2));
      return;
    }
    case "operations": {
      console.log(JSON.stringify(plane.listOperations(), null, 2));
      return;
    }
    default: {
      const _unknown: never = cmd as never;
      void _unknown;
      usage();
    }
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
