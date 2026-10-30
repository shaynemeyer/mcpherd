---
name: cleanup
description: Clean up project housekeeping tasks (add "run" to execute fixes)
---

Review the project for housekeeping issues. Read `context/ai-interaction.md` and
`context/coding-standards.md` first (or the root `AGENTS.md` if those don't exist) for the
project's languages, source directories, and lint commands. Skip any check that doesn't apply to
this project. Skip `.venv/`, `node_modules/`, `vendor/`, `target/`, build output, caches, and
vendored files.

1. Feature history: entries are in order from oldest to newest, and `context/current-feature.md`
   holds at most one entry under `## History`. Anything older belongs in
   `context/feature-history.md`. Skip this check if those files don't exist.
2. Leftover debug output in source code: `console.log` and `debugger` in JS/TS; `print()`,
   `breakpoint()`, and `pdb` in Python; `fmt.Print*`, `println()`, and `log.Print*` used for
   debugging in Go; `dbg!`, `println!`, and `eprintln!` used for debugging in Rust. Skip cases where
   printing is the program's job (CLI output) and test files (`*_test.go`, Rust `#[cfg(test)]`
   modules and `tests/`)
3. Unused imports. Prefer the project's linter output over inspection (`cargo clippy` for Rust).
   Skip this check for Go, where the compiler rejects unused imports.
4. Stale `TODO` / `FIXME` comments, such as ones referring to work that is done or features that
   have shipped
5. Orphaned or unused files: modules nothing imports, templates or static assets nothing references,
   and leftover scratch files
6. Context files that no longer match the project: check stated commands, versions, directory
   layout, "not yet built" claims, and evidence gaps in `context/*.md` and `AGENTS.md` against what
   the repository actually contains
7. Environment variables: compare the key names in each env file (`.env`, `.env.example`,
   `.env.production`, and so on) with each other and with the settings the code reads. Report keys
   that are missing or undocumented. **Report key names only, never values.** Use file-reading tools
   rather than shell commands for these files.
8. Type-check and lint suppressions that may be stale or unexplained: `@ts-ignore`,
   `@ts-expect-error`, `# type: ignore`, `# noqa`, `eslint-disable`, Go's `//nolint` and
   `//lint:ignore`, and Rust's `#[allow(...)]` and `#![allow(...)]`

**Mode: pass "run" to execute fixes, or "check" (the default) to only report.**

If there is no argument, or the argument is "check":

- Only report findings; don't modify anything
- List what WOULD be cleaned up

If the argument is "run" or "fix":

- First, report all findings as numbered items
- Then ask: "Which items would you like me to fix? (enter numbers like 1,3,5 or 'all' or 'none')"
- Wait for the user's response before making any changes
- Fix only the items the user specifies
- Run the project's lint and test commands from `context/ai-interaction.md`
- Report what you changed
