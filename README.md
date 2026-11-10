# bun-oxc-monorepo-template

A starting point for TypeScript monorepos on [Bun](https://bun.sh), formatted with [oxfmt](https://oxc.rs/docs/guide/usage/formatter) and linted with type-aware [oxlint](https://oxc.rs/docs/guide/usage/linter), with git hooks and Claude Code hooks that run the checks for you.

## Create a project

```sh
bun create josefaidt/bun-oxc-monorepo-template my-project
```

`bun create` copies the files without this repository's history, renames the root package to the directory name, runs `git init` and `bun install`, and tries a first commit. The `commit-msg` hook rejects that commit's message, so the files stay staged for a first commit of your own, such as `chore: initial commit`.

Then replace the description at the top of this README and under "What this is" in `AGENTS.md`, and install the agent skills `AGENTS.md` lists.

## Stack

| Tool | Does |
| :-- | :-- |
| [Bun](https://bun.sh) | Package manager, script runner, and type checker (`bun check`), at the version in `.bun-version` |
| [TypeScript 7](https://www.typescriptlang.org) | Strict baseline in `tsconfig.base.json` that every package extends |
| [oxfmt](https://oxc.rs/docs/guide/usage/formatter) | Formatting, import order, and `package.json` key order |
| [oxlint](https://oxc.rs/docs/guide/usage/linter) | Type-aware linting on the `correctness`, `suspicious`, `pedantic`, and `perf` categories |
| [Vitest](https://vitest.dev) | Each package's tests |
| [commitlint](https://commitlint.js.org) | [Conventional Commits](https://www.conventionalcommits.org) on every message |
| [rolldown](https://rolldown.rs) | Builds for the packages that ship compiled output |

## Development

```sh
bun run setup
```

`bun run setup` installs dependencies, creates each missing `.env.local` from its `.env.example`, and builds the packages with a build step. Every step is idempotent, so re-run it to repair a checkout.

| Command             | Does                                         |
| :------------------ | :------------------------------------------- |
| `bun run test`      | Runs each workspace's Vitest suite           |
| `bun run typecheck` | Type checks every workspace with `bun check` |
| `bun run lint`      | Lints with type-aware oxlint                 |
| `bun run fmt`       | Formats with oxfmt                           |
| `bun run build`     | Builds each package with a build step        |

Run `bun run test`, never `bun test`, which starts Bun's own test runner instead of each package's Vitest suite.

## Hooks

`bun install` points git at `.git-hooks/`. The `pre-commit` hook checks the formatting and lint of what is staged, `commit-msg` checks each message with commitlint, and `post-rewrite` reinstalls after a rebase that changed a dependency.

Claude Code runs the hooks in `.claude/settings.json`: setup when a session starts, formatting after each edit, and formatting, lint, and type checks on what each turn changed before the turn can end.

## Layout

| Folder      | Holds                                                      |
| :---------- | :--------------------------------------------------------- |
| `apps/`     | What you run or deploy, such as a server, a site, or a CLI |
| `packages/` | What other workspaces import                               |
| `scripts/`  | Repo tooling, such as `setup.sh`                           |

Dependencies that more than one package uses live in the [catalog](https://bun.sh/docs/pm/catalogs) in the root `package.json`, and each package references them as `catalog:`.

## Adding a package

With the skills installed, ask Claude Code to add one, or run the `new-typescript-package` skill:

```
/new-typescript-package <name> [packages|apps]
```

By hand, create `packages/<name>/` or `apps/<name>/` with:

- `package.json`, named `@workspace/<name>`, with `exports` pointing at `./<name>.ts`, a `typecheck` script that runs `bun check`, and a `test` script that runs `vitest run` once the package has a test
- `tsconfig.json`, extending `../../tsconfig.base.json` and listing the runtime's types, such as `"types": ["bun"]`
- `<name>.ts`, the entrypoint

A package consumed only inside the monorepo exports raw `.ts` and has no build. A package that ships compiled output builds with rolldown, and its `exports` lists the `@workspace/source` condition first, pointing at `./<name>.ts`, so the type checker and the tests read source while an app loads `dist/`.
