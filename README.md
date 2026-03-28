# bun-oxc-monorepo-template

A monorepo template using [Bun](https://bun.sh), [oxlint](https://oxc.rs/docs/guide/usage/linter), and [oxfmt](https://oxc.rs/docs/guide/usage/formatter) for fast, modern TypeScript development.

## Stack

| Tool | Purpose |
|------|---------|
| [Bun](https://bun.sh) | Package manager, runtime, and test runner |
| [TypeScript 6](https://www.typescriptlang.org) | Language — executed directly by Bun, no transpile step |
| [oxlint](https://oxc.rs/docs/guide/usage/linter) | Linter — Rust-based, significantly faster than ESLint |
| [oxfmt](https://oxc.rs/docs/guide/usage/formatter) | Formatter — no semicolons, sorted imports |
| [rolldown](https://rolldown.rs) | Bundler for packages that need a compiled output |

## Structure

```
apps/        # application packages
packages/    # shared library packages
```

Dependencies shared across packages are managed via the [Bun catalog](https://bun.sh/docs/pm/catalogs) in the root `package.json`. Reference them with `catalog:` in workspace package `devDependencies`.

## Getting Started

```bash
bun install
```

## Commands

```bash
bun run lint         # lint with oxlint
bun run lint:fix     # lint and auto-fix
bun run fmt          # format with oxfmt
bun run fmt:check    # check formatting without writing
bun test             # run tests across all workspaces
bun run build        # build all packages
```

## Adding a Package

New packages are scaffolded from instructions rather than a template directory. If you're using Claude Code, invoke the `new-package` skill:

```
/new-package <name> [packages|apps]
```

Otherwise, create `packages/<name>/` (or `apps/<name>/`) with:

- `package.json` — set `name` to `@workspace/<name>`, `exports` to `./<name>.ts`
- `tsconfig.json` — extend `../../tsconfig.base.json`, set `"types": ["bun"]`
- `<name>.ts` — the package entrypoint

For packages with a compiled output, add a `rolldown.config.ts`. For packages consumed only within the monorepo, skip the build step entirely and export raw `.ts`.

## TypeScript Configuration

The base `tsconfig.base.json` is strict by default:

- `moduleResolution: "bundler"` and `verbatimModuleSyntax`
- All `noImplicit*`, `noUnused*`, and `strictNull*` checks enabled
- `"types": []` — add type packages (e.g. `@types/bun`) per-package as needed
