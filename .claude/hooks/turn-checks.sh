#!/usr/bin/env bash
# Formats, lints, and type checks what each turn changed, so the agent never spends a tool call on
# the formatter, the linter, or the type checker.
#
# On UserPromptSubmit (`snapshot`) it records the working tree as the turn's base. On Stop (`check`)
# it checks every file that differs from that base, whether an Edit, a Write, a shell command, or a
# subagent changed it, and on a failure exits 2, which hands the output back to Claude and keeps the
# turn going until the checks pass. The base moves forward only once they pass, so a failure the
# turn could not fix is checked again at the end of the next one, while a file the user edits
# between two passing turns is never checked.
#
# Anything a UserPromptSubmit hook prints to stdout is injected into Claude's context, so nothing
# goes to stdout.
set -euo pipefail

# shellcheck source=session-workspace.sh
source "$(dirname "${BASH_SOURCE[0]}")/session-workspace.sh"
input="$(cat)"
workspace="$(resolve_session_workspace "$input")"
workspace="$(git -C "$workspace" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$workspace"

# The extensions oxfmt formats and oxlint lints, matching .git-hooks/pre-commit
FORMATTED='\.(ts|tsx|js|jsx|cjs|mjs|cts|mts|json|jsonc|yaml|yml|toml|css|scss|less|md|mdx|graphql|vue|svelte|html)$'
LINTED='\.(ts|tsx|js|jsx|cjs|mjs|cts|mts|vue|svelte|astro)$'
# A change to one of these can break a file that did not change, so it runs that check on the repo
FORMATS_ALL='^\.oxfmtrc\.jsonc?$'
LINTS_ALL='(^|/)\.oxlintrc\.jsonc?$'
TYPECHECKS='\.(ts|tsx|cts|mts)$|(^|/)tsconfig[^/]*\.json$|(^|/)package\.json$|^bun\.lock$'

session=default
if [[ $input =~ \"session_id\":\ *\"([A-Za-z0-9_-]+)\" ]]; then
  session="${BASH_REMATCH[1]}"
fi
# inside the git dir, so the state of a worktree goes away with it
state="$(git rev-parse --path-format=absolute --git-path claude-turn-checks)"
mkdir -p "$state"
base="$state/$session.base"
pending="$state/$session.pending"

# Hashes the working tree into a tree object by staging everything into a copy of the index. The copy
# keeps the real index untouched, and starting from it lets git rehash only the files whose stat data
# changed.
write_tree() {
  local dir index
  dir="$(mktemp -d)"
  index="$(git rev-parse --git-path index)"
  if [[ -f $index ]]; then cp "$index" "$dir/index"; fi
  GIT_INDEX_FILE="$dir/index" git add --all >/dev/null
  GIT_INDEX_FILE="$dir/index" git write-tree
  rm -rf "$dir"
}

changed=""
failed=0

# Prints the changed paths that match an extended regex.
matching() {
  printf '%s\n' "$changed" | grep -E "$1" || true
}

# Runs a command, and prints its output only when it fails. Output that says every file was ignored
# counts as a pass.
run() {
  local output
  if output="$("$@" 2>&1)"; then return 0; fi
  case "$output" in
  *"Expected at least one target file"* | *"No files found to lint"*) return 0 ;;
  esac
  printf '$ %s\n%s\n\n' "$*" "$output"
  failed=1
}

# Runs a command with newline-separated paths appended as arguments, keeping any spaces in a path.
run_on() {
  local paths="$1"
  shift
  run xargs -0 "$@" < <(printf '%s\n' "$paths" | sed 's|^|./|' | tr '\n' '\0')
}

# Formats and lints the files that changed since a tree, and type checks the repo when a file the
# type checker reads changed. Prints the output of each check that fails.
check_since() {
  changed="$(git diff --name-only --no-renames --diff-filter=d "$1" "$(write_tree)")"
  [[ -n $changed ]] || return 0
  if [[ -n "$(matching "$FORMATS_ALL")" ]]; then
    run bun run fmt
  elif [[ -n "$(matching "$FORMATTED")" ]]; then
    run_on "$(matching "$FORMATTED")" bun run fmt
  fi
  if [[ -n "$(matching "$LINTS_ALL")" ]]; then
    run bun run lint
  elif [[ -n "$(matching "$LINTED")" ]]; then
    run_on "$(matching "$LINTED")" bun run lint
  fi
  if [[ -n "$(matching "$TYPECHECKS")" ]]; then
    run bun run typecheck
  fi
  return "$failed"
}

case "${1:-}" in
snapshot)
  [[ -f $pending ]] || write_tree >"$base"
  ;;
check)
  # without a base, such as in the first turn after the hook was installed, there is no telling
  # what this turn changed, so start tracking from here
  if [[ ! -s $base ]] || ! git cat-file -e "$(cat "$base")^{tree}" 2>/dev/null; then
    write_tree >"$base"
    exit 0
  fi
  if output="$(check_since "$(cat "$base")" 2>&1)"; then
    rm -f "$pending"
    write_tree >"$base"
    exit 0
  fi
  touch "$pending"
  printf 'These checks failed on the files this turn changed in %s. Fix them before you finish; the hook reruns them.\n\n%s\n' "$workspace" "$output" >&2
  exit 2
  ;;
*)
  echo "usage: turn-checks.sh snapshot|check" >&2
  exit 1
  ;;
esac
