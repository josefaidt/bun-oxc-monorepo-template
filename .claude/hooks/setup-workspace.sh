#!/usr/bin/env bash
# Brings a workspace up to a runnable state. Runs on session start and after EnterWorktree, so it
# fires in fresh worktrees, which start with none of the gitignored state a working checkout needs.
#
# The steps themselves live in scripts/setup.sh, the same command the README tells a person to run,
# so automation and docs cannot drift apart. This hook only decides whether a workspace needs the
# full bootstrap or a refresh.
#
# Anything a SessionStart hook prints to stdout is injected into Claude's context, so all output
# goes to stderr.
set -euo pipefail

# shellcheck source=session-workspace.sh
source "$(dirname "${BASH_SOURCE[0]}")/session-workspace.sh"
input=""
[[ -t 0 ]] || input="$(cat)"
workspace="$(resolve_session_workspace "$input")"
cd "$workspace"
echo "[setup-workspace] bootstrapping $workspace" >&2

# A warm workspace can still hold node_modules from before a pull changed bun.lock, so it installs
# from the lockfile, which takes well under a second when nothing changed and fails when a
# package.json asks for a package bun.lock lacks. It rebuilds the packages with a build step too,
# since an app that loads one from dist/ would otherwise run against a stale build. Add any other
# gitignored state the repo generates, such as generated types, to both branches.
if [[ -d node_modules ]]; then
  bun ci >&2
  bun run build >&2
  exit 0
fi

echo "[setup-workspace] cold workspace, running scripts/setup.sh" >&2
./scripts/setup.sh >&2
