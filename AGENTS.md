# AGENTS.md

Guidance for coding agents working in this repository. `CLAUDE.md` is a symlink to this file, so Claude Code, Codex, and anything else reading `AGENTS.md` all get the same instructions. Edit this file, never the symlink.

This file holds what every session needs before it picks a skill, plus pointers. A rule that matters for one kind of task goes in the skill or document that governs that task.

`README.md` is the human-facing entry point. When onboarding someone, point them at it and `bun run setup`, since `scripts/setup.sh` is the single source of truth for what a checkout needs.

## What this is

A starting point for TypeScript monorepos on Bun, with oxfmt, type-aware oxlint, Vitest, Conventional Commits, and Claude Code hooks that run the checks on each turn. When a project starts from it, replace this paragraph with what that project is and who it is for.

## Skills

The skills come from [josefaidt/skills](https://github.com/josefaidt/skills), and this repository does not ship copies of them. Install them once per project, then commit what the CLI writes:

```sh
bunx skills add josefaidt/skills --skill writing-typescript --skill new-typescript-package --skill monorepo --skill writing-prose --skill domain-modeling --skill retro -a claude-code -a codex -y
bunx skills add github/awesome-copilot --skill conventional-commit -a claude-code -a codex -y
bun run fmt
```

Installed skills live in `.agents/skills/`, symlinked into `.claude/skills/`. Load the matching skill before starting the work it covers.

| Skill | Load when |
| :-- | :-- |
| `writing-typescript` | Writing or reviewing any TypeScript |
| `new-typescript-package` | Adding a workspace package or app |
| `monorepo` | Deciding where code belongs, or adding or upgrading a dependency |
| `writing-prose` | Writing any prose, such as a README, an issue, or a pull request body |
| `domain-modeling` | Naming or renaming a domain concept, or editing `GLOSSARY.md` or an ADR |
| `conventional-commit` | Writing a commit message |

`retro` runs only when the user invokes it by name, and codifies what a session taught into the files future agents read.

Skills vendored from other repositories are pinned in `skills-lock.json`. Change them upstream and run `bunx skills update` rather than editing the copies here.

## Local setup

`bun run setup` bootstraps a checkout. Every step is idempotent, so re-run it to repair a workspace rather than debugging a half-set-up one. Claude Code sessions run it through a `SessionStart` hook, including in new worktrees.

Search the tree with `git grep`, which never opens a gitignored file such as `.env.local`.

Hooks run the static checks, so a Claude Code session never spends a tool call on them. A `PostToolUse` hook formats each file an `Edit` or `Write` changes, and a `Stop` hook formats, lints, and type checks everything the turn changed and hands any failure back before the turn can end. Do not run the formatter, the linter, or the type checker to confirm an edit; when the hook blocks, fix what it reports. Tests are not part of it, so run the ones a change needs. An agent without these hooks, such as Codex, runs `bun run fmt`, `bun run lint`, and `bun run typecheck` before it finishes.

## Project structure

A TypeScript monorepo on Bun workspaces.

- `apps/` holds what you run or deploy, such as a server, a site, or a CLI. Nothing imports an app.
- `packages/` holds what other workspaces import. A package has an entrypoint and no deploy target.

Every workspace package is named `@workspace/<name>`, and `tsconfig.base.json` names the matching `@workspace/source` export condition, which points the type checker and the tests at a built package's TypeScript source.

## Commands

This project uses `bun`, never `npm` or `pnpm`, at the version pinned in `.bun-version`. Run commands from the repo root.

- `bun run --filter <package-name> <script>` runs one workspace's script; `--filter '*'` fans out to all.
- `bun run test` runs each workspace's Vitest `test` script. Never run `bun test`, which starts Bun's own runner.
- `bun run typecheck` checks every workspace with `bun check`.
- `bun run build` builds each package with a build step into its `dist/`.
- `bun run fmt` and `bun run lint` (oxfmt and type-aware oxlint), with `fmt:check` and `lint:fix`.
- One-off `.ts` scripts run directly with `bun run <file>`.

## Markdown

Write each paragraph and list item in any markdown as one unbroken line, even in a file that is already hard-wrapped, since oxfmt keeps line breaks and never reflows them.

## Commits and pull requests

Commit messages and pull request titles follow Conventional Commits, `type(scope): summary`, and the `commit-msg` hook checks them with commitlint. When a branch needs commits from `main`, rebase it onto `origin/main` and push with `git push --force-with-lease`. Do not merge `main` into it.
