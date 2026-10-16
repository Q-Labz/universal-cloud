#!/usr/bin/env bash
# Fail if infrastructure code grants basic primitive admin roles or creates
# service account keys. docs/ is not scanned so the runbook can name the roles
# operators must audit for. Markdown under infra/ is scanned.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

mapfile -d '' files < <(
  find infra .github -type f \
    \( -name '*.tf' -o -name '*.tfvars' -o -name '*.hcl' -o -name '*.yml' -o -name '*.yaml' -o -name '*.json' -o -name '*.md' \) \
    ! -path '*/.terraform/*' \
    -print0
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No infrastructure files to scan."
  exit 1
fi

failed=0
for file in "${files[@]}"; do
  if grep -nE 'roles/(owner|editor)([^A-Za-z0-9_-]|$)' "$file"; then
    echo "Forbidden basic role in ${file}."
    failed=1
  fi
  if grep -nE 'google_service_account_key|BEGIN PRIVATE KEY|BEGIN RSA PRIVATE KEY' "$file"; then
    echo "Service account key material in ${file}."
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "Privileged IAM check failed."
  exit 1
fi

echo "Privileged IAM check passed (${#files[@]} files)."
