---
name: new-package
description: Scaffold a new package or app in the monorepo. Use when asked to create a new package or app.
argument-hint: <name> [apps|packages]
---

# New Package

Scaffold a new package in the monorepo from scratch. Do not copy `packages/template` — it no longer exists.

The first argument is the package name (e.g. `utils`). The second optional argument is the directory (`packages` or `apps`), defaulting to `packages`.

## Steps

1. Determine the destination: `packages/<name>` or `apps/<name>`
2. Create the following files:

### `package.json`

```json
{
  "name": "@workspace/<name>",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": "./<name>.ts"
  },
  "scripts": {
    "build": "rolldown -c",
    "test": "bun test",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "@types/bun": "catalog:",
    "rolldown": "catalog:",
    "typescript": "catalog:"
  }
}
```

Only include `rolldown` in `devDependencies` if the package needs a compiled output. For monorepo-internal packages, omit `rolldown` and the `build` script.

### `tsconfig.json`

```json
{
  "$schema": "https://json.schemastore.org/tsconfig.json",
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "types": ["bun"]
  },
  "include": ["./**/*.ts"]
}
```

Adjust the `extends` path depth to match the actual location (e.g. `apps/<name>` also uses `../../tsconfig.base.json`).

### `<name>.ts`

The package entrypoint. Start with an empty export:

```typescript
export {}
```

### `rolldown.config.ts` (only if the package has a build step)

```typescript
import { defineConfig } from "rolldown"

export default defineConfig({
  input: "<name>.ts",
  output: {
    dir: "dist",
    format: "esm",
  },
})
```

## After Scaffolding

Run `bun install` from the repo root to link the new workspace package.

## Notes

- Use `catalog:` for any dependency version that exists in the root `package.json` catalog
- Use `workspace:*` to reference other internal packages
- For packages consumed only within the monorepo, skip `rolldown` and export raw `.ts` directly
- The entrypoint **must** be `<name>.ts` at the package root — never `src/index.ts`
- Never use barrel files — import directly from specific files
