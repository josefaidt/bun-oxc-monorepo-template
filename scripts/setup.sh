#!/usr/bin/env bash
# One-command local bootstrap: dependencies, local env files, and the packages with a build step.
# Safe to re-run at any time, since every step is idempotent, so this is also the way to repair a
# half-set-up workspace. Add each new step the repo needs here, and keep it idempotent.
set -euo pipefail

cd "$(dirname "$0")/.."

# CI installs dependencies through .github/actions/setup and sets SKIP_INSTALL=1, so the install
# runs only once
if [[ "${SKIP_INSTALL:-}" != "1" ]]; then
  echo "==> installing dependencies"
  bun ci
fi

echo "==> creating missing .env.local files from their examples"
# never overwrite an existing .env.local, which may hold real values
for example in .env.example apps/*/.env.example packages/*/.env.example; do
  [[ -e "$example" ]] || continue
  local_env="${example%.example}.local"
  if [[ ! -e "$local_env" ]]; then
    cp "$example" "$local_env"
    echo "    created $local_env"
  fi
done

# an app that loads a package from dist/ runs against what this builds
echo "==> building the packages with a build step"
bun run build

echo "==> ready"
