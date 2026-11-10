#!/usr/bin/env bash
# Sourced by the hooks that act on a checkout, to decide which one. A session forked into a new
# worktree can keep the original checkout as its project dir, so a hook that trusts
# CLAUDE_PROJECT_DIR or its own directory works on a checkout the session never edits. The hook's
# input names the session's own directory in `cwd`, which decides, with the project dir as the
# fallback. The directory must be a worktree of this repository, so a hook never acts on another
# repository.

# Prints the root of the checkout the session works in. Takes the hook's input JSON, which may be
# empty.
resolve_session_workspace() {
  local input="$1" session_dir="" toplevel project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
  if command -v jq >/dev/null 2>&1; then
    session_dir="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
  fi
  if toplevel="$(git -C "${session_dir:-.}" rev-parse --show-toplevel 2>/dev/null)" &&
    [[ "$(git -C "$toplevel" rev-parse --path-format=absolute --git-common-dir)" == \
      "$(git -C "$project_dir" rev-parse --path-format=absolute --git-common-dir)" ]]; then
    printf '%s\n' "$toplevel"
  else
    printf '%s\n' "$project_dir"
  fi
}
