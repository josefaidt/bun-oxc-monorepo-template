# CLAUDE.md

This file provides guidance to coding agents (Claude Code, Cursor, Copilot, etc.) when working with code in this repository.

## Project Structure

This is a Bun monorepo using oxlint and oxfmt for linting and formatting.

```
apps/        # application packages
packages/    # shared library packages
```

## Package Manager

This project uses **Bun** as the package manager and runtime. Common dependency versions are managed via the [catalog](https://bun.sh/docs/pm/catalogs) defined in the root `package.json`. Reference catalog entries with `catalog:` in workspace package `devDependencies`.

## Common Commands

```bash
bun install          # install all workspace dependencies
bun run lint         # lint with oxlint
bun run lint:fix     # lint and auto-fix
bun run fmt          # format with oxfmt
bun run fmt:check    # check formatting without writing
bun test             # run tests across all workspaces
```

## Tooling

### TypeScript

- Base configuration in `tsconfig.base.json` — strict, `moduleResolution: "bundler"`, `verbatimModuleSyntax`
- TypeScript 6: `"types": []` is set explicitly — add type packages per-package as needed (e.g. `"types": ["bun"]`)
- Raw TypeScript executed directly by Bun — no build/transpile step needed for development

### Linting & Formatting

- `oxlint` — configured via `.oxlintrc.json`
- `oxfmt` — configured via `.oxfmtrc.json`; no semicolons, sorted imports

## TypeScript Development Approach

See the `authoring-typescript` skill (`.claude/skills/authoring-typescript/SKILL.md`) for detailed TypeScript best practices including import style and directory conventions.

## Adding a New Package

See the `new-package` skill (`.claude/skills/new-package/SKILL.md`) for step-by-step scaffolding instructions.
