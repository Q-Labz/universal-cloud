#!/usr/bin/env bash
# Offline OpenTofu check: fmt, then init without a backend, then validate.
# This script never runs plan or apply and never talks to a GCP API.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
infra_root="${repo_root}/infra"

export TF_IN_AUTOMATION=1
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-/tmp/tofu-plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

"${repo_root}/infra/ci/forbid-privileged-iam.sh"

echo "Checking OpenTofu formatting."
tofu fmt -check -recursive -diff "$infra_root"

mapfile -t dirs < <(find "$infra_root/modules" "$infra_root/live" -name versions.tf -printf '%h\n' | sort)
if [[ ${#dirs[@]} -eq 0 ]]; then
  echo "No OpenTofu roots found."
  exit 1
fi

for dir in "${dirs[@]}"; do
  echo "Validating ${dir#"$repo_root"/}."
  tofu -chdir="$dir" init -backend=false -input=false -no-color
  tofu -chdir="$dir" validate -no-color
done

echo "Offline validation passed."
