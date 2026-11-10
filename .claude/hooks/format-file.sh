#!/usr/bin/env bash
# Formats the file an Edit or Write just changed, so the agent reads formatted code back and never
# runs the formatter itself. turn-checks.sh formats anything else a turn changes, such as a file
# a shell command wrote, and reports a file the formatter cannot parse.
set -euo pipefail

# shellcheck source=session-workspace.sh
source "$(dirname "${BASH_SOURCE[0]}")/session-workspace.sh"
input="$(cat)"
workspace="$(resolve_session_workspace "$input")"
workspace="$(git -C "$workspace" rev-parse --show-toplevel 2>/dev/null)" || exit 0
file="$(printf '%s' "$input" | bun -e 'const input = await Bun.stdin.json(); process.stdout.write(input.tool_input?.file_path ?? "")')"
# a file outside this checkout, such as one in the scratchpad, is not this repo's to format
[[ $file == "$workspace"/* ]] || exit 0
cd "$workspace"
# a file mid-edit may not parse yet, which the Stop hook reports once the turn ends
bun run fmt "$file" >/dev/null 2>&1 || true
