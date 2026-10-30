# Feature Skill: Spec Frontmatter Plan

**Status:** Implemented 2026-10-30 on branch `chore/spec-frontmatter`. See "Implementation notes"
for where the build differs from the design below.

This plan covers changes to the `feature` skill in `.kiro/skills/feature/`. Claude Code reads the
same files through the `.claude/skills/feature` symlink. It is not part of mcpherd itself.

## Goal

Move each spec's machine-read data (status, dependencies, and the files it touches) out of prose
lines and into YAML frontmatter at the top of the file, so actions read it exactly instead of
pattern-matching text. The specs stay markdown: readable, diffable in pull requests, and editable
by hand.

## Non-goals

- A database or index. Markdown stays the only source of truth (see "Why not a database").
- A YAML library or any new install. Reading uses `sh`, `awk`, `find`, `sort` and `tsort`, which
  ship with macOS, Linux and Git for Windows.
- Frontmatter in `context/current-feature.md`. Its `**Spec:**` line is a single value the actions
  already read reliably. Revisit with the parallel plan's `## Batch` table if that proves fragile.
- Full YAML. The skill writes, and reads, a small fixed subset (see "Format rules").

## Problem

The skill reads three kinds of data from spec prose today:

| Data | Today | Weakness |
| --- | --- | --- |
| Status | `**Status:** Not Started` line under the H1, found with anchored `grep` patterns in `SKILL.md` | The patterns needed several fixes (anchoring, zsh empty-glob failures, fixes folder). `Complete — merged YYYY-MM-DD (<sha>)` packs three facts into one string. |
| Dependencies | `**Depends on:** none` or comma-separated filenames | `complete` step 10 says the line "has no single format" (filenames, numbers, ranges such as "features 91–99"), so the agent must read it rather than parse it. "Next up" in `status` and the parallel plan's independence check depend on it. |
| Touches | A `## Touches` section of free-form bullets | The parallel plan's overlap check needs to compare these across specs. Prose bullets can't be compared exactly. |

## Design

### The frontmatter

```yaml
---
status: Not Started
depends_on:
  - 01-core-types
  - 02-config
touches:
  - internal/llm/ollama/
  - cmd/mcpherd/main.go
---

# Chat client

## Context
...
```

| Field | Required | Values |
| --- | --- | --- |
| `status` | yes | `Not Started`, `In Progress` or `Complete` |
| `merged` | when `status: Complete` | `YYYY-MM-DD (<sha>)`, the merge date and commit `complete` records |
| `depends_on` | yes | Spec ids (filename without `.md`) of specs in `context/features/` or `context/fixes/`, or `[]` for none |
| `touches` | yes | File and folder paths the spec creates or changes, relative to the repository root, with a trailing `/` for a folder, or `[]` while unknown. Paths only (see "Decisions") |

The spec id is the filename. It is not repeated in the frontmatter, so it can't drift.

### What moves out of the body

- The `**Status:**` and `**Depends on:**` lines are removed. Frontmatter is the only copy.
- The `## Touches` section is removed. Notes about why a spec touches something go under
  `## Notes`.
- Everything else stays: the H1 and the Context, Goals, Acceptance Criteria, Non-goals, Notes and
  Testing sections.

GitHub and GitLab render frontmatter as a small table at the top of the file, so a spec is still
readable in the browser.

### Format rules

The skill writes only this subset of YAML, which keeps it readable by `awk`:

- The file's first line is `---`, and the frontmatter ends at the next `---` line.
- One `key: value` per line, with keys in lower case and underscores. No quotes, and no `#`
  comments inside the frontmatter.
- Lists use block style: the key alone (`depends_on:`), then one `  - item` line per item,
  indented two spaces. An empty list is written `[]` on the key's line.
- No nested maps, multi-line strings or anchors.

`audit` reports and fixes anything outside these rules.

### Reading it: `scripts/spec-fields.sh`

A short POSIX shell script in the skill's directory prints one line per value:
`<spec-id> TAB <field> TAB <value>`. Lists print one line per item. A file with no frontmatter
prints an `_error` line. Every query builds on it:

| Query | Used by | How |
| --- | --- | --- |
| Status of each spec | `status`, `load`, `audit`, `complete` | rows where field is `status` |
| Outstanding specs | `status`, `audit`, `complete` step 10 | `status` is not `Complete` |
| Stale `In Progress` | `load`, `status` | `status` is `In Progress` and the id isn't the one on the `**Spec:**` line |
| Next up | `status` | lowest-numbered outstanding spec whose `depends_on` entries are all `Complete` |
| Dependents of a spec | `complete` step 10 | rows where field is `depends_on` and value is that id |
| Dependency order and cycles | `plan`, `audit` | `depends_on` pairs piped to `tsort`; a `cycle in data` message means a cycle |
| Overlapping touches | `audit`, parallel independence check | `touches` values that appear under more than one spec |
| Malformed specs | `audit`, `status` | `_error` rows, unknown `status` values, `depends_on` ids with no file |
| Old-format specs | every action that reads specs | `_error: no frontmatter`; stop and point to `audit` |

The script searches the folders with `find`, so empty or missing folders are not an error, and
it reads only the frontmatter block, so a body line that starts with `status:` is ignored.

**Prototype (2026-10-30).** A 25-line version ran on macOS with BSD `awk` and `tsort` against
sample specs. It printed every field, ignored a `status:` line in a spec body, flagged an
old-format spec as having no frontmatter, picked the right "next up", found two specs touching
`cmd/mcpherd/main.go`, produced a dependency order, and returned no rows for an empty
`context/features/` and a missing `context/fixes/`. One finding: macOS `tsort` exits 0 when it
finds a cycle, so the cycle check has to look for `cycle in data` in its output rather than rely
on the exit code.

**Windows.** The script needs `sh`, which Git for Windows provides. Where no shell is available,
the agent reads the frontmatter of each file directly; the format rules make that unambiguous.

### Writing it

Actions edit frontmatter values in place with the file-editing tool, the same way they edit any
other line, and never rewrite the whole block. After writing, the action re-reads the value with
`spec-fields.sh` to confirm it.

## Changes by file

| File | Change |
| --- | --- |
| `templates/spec.md` | Frontmatter block with the four fields; remove the `**Status:**` and `**Depends on:**` lines and the `## Touches` section; placeholder comment explaining the fields |
| `scripts/spec-fields.sh` | New |
| `SKILL.md` | "Spec Files": describe the frontmatter, the format rules and the queries, replacing the `grep` patterns. Statuses become `status` plus `merged`. Note that `In Progress` still has a single holder |
| `actions/plan.md` | Write frontmatter; `depends_on` as spec ids; `touches` as best-estimate paths; run the `tsort` check on the new specs and report cycles |
| `actions/load.md` | Read `status` from frontmatter (step 2); find stale `In Progress` with the script (step 3); specs written from an inline description get frontmatter (step 1) |
| `actions/start.md` | Set `status: In Progress` |
| `actions/status.md` | Counts, next up and stale markers from the script; report malformed specs and cycles |
| `actions/audit.md` | Dependencies check compares body references with `depends_on`; collision check uses `touches` across specs; structure check validates frontmatter against the format rules, and converts old-format specs (see "Migration") |
| `actions/complete.md` | Step 7 sets `status: Complete` and `merged: YYYY-MM-DD (<sha>)`; step 10 finds dependents with the script instead of reading prose, and adds this spec to a spec's `depends_on` when it depends on it without saying so |
| `actions/abandon.md` | Set `status: Not Started` |
| `README.md`, `templates/README.md` | Describe the frontmatter as a fixed convention |
| `docs/plans/FEATURE_SKILL_PARALLEL_PLAN.md` | Independence checks 1–3 read `depends_on`, `status` and `touches` through the script; drop the prose-based caveats |

## Migration

Projects set up before this change have specs with `**Status:**` and `**Depends on:**` lines and a
`## Touches` section. mcpherd has none yet, so it needs no migration.

- **Actions read only frontmatter.** There is no code path for the old format. When
  `spec-fields.sh` reports `_error: no frontmatter` for a spec, the action stops before changing
  anything, names the spec, and says to run `audit` to convert it.
- **`audit` converts, once.** Its structure check rewrites an old-format spec: status and merge
  details into `status` and `merged`, the `Depends on:` line into `depends_on` ids (resolving
  numbers and ranges such as "features 91–99" to filenames, and asking when one is ambiguous), and
  the `## Touches` bullets into `touches` paths. It shows the converted frontmatter and asks before
  writing. Bullets that aren't paths move to `## Notes`.

## Why not a database

Considered: DuckDB or SQLite holding spec state. Rejected:

- Binary database files can't be reviewed or merged in pull requests, while every spec change is a
  readable diff today.
- Every machine and CI job would need the database installed, at a matching version.
- A database file allows one writer at a time, which works against parallel runs.
- The specs must stay readable as text anyway, so the database would be a second copy that drifts.

Revisit if a project reaches hundreds of specs or needs reports across many repositories. Even
then, build a read-only, git-ignored index from the markdown when needed, and keep the markdown as
the source of truth.

## Risks

- **Hand edits outside the format rules**, such as a flow list `[a, b]` with items or a quoted
  value. `spec-fields.sh` would misread them. `audit` and `status` report specs that don't parse
  cleanly, and `audit` fixes them.
- **Half-converted specs.** A spec edited by hand could carry both a frontmatter `status` and an
  old `**Status:**` line. `audit` removes the old line when it converts, and treats a spec with both
  as malformed.
- **Collisions that paths miss.** Two specs could add the same setting or command in different
  files. In this Go layout, each kind of name lives in a predictable file, so the paths usually
  overlap anyway. If `audit` finds a clash that paths missed, add name prefixes to `touches` then;
  existing path-only specs stay valid.
- **Tool differences.** BSD and GNU `awk`, `find` and `tsort` differ in small ways. The prototype
  ran on macOS; test on Linux before release.

## Implementation order

1. `scripts/spec-fields.sh`, with test specs covering every row in the queries table, run on
   macOS and Linux.
2. `templates/spec.md` and `SKILL.md` "Spec Files".
3. The actions, in this order: `plan`, `load`, `start`, `status`, `audit` (including conversion),
   `complete`, `abandon`.
4. `README.md`, `templates/README.md`, and the parallel plan's independence checks.
5. Trial: run `plan` on `docs/plans/GO_PORT_PLAN.md`, then `status`, `audit` and a `load`. Check the
   reported next up and dependency order by hand.

## Decisions

Decided 2026-10-30.

1. **This plan comes before the parallel plan.** The parallel action's independence check is the
   biggest user of `depends_on` and `touches`, so it is built on exact data from the start.
2. **`touches` holds paths only.** No `config:`, `cmd:`, `test:` or `name:` prefixes for now.
   Paths catch most collisions, and prefixes can be added later without breaking existing specs
   (see "Risks").
3. **No old-format fallback.** Actions read only frontmatter. An action that finds an old-format
   spec stops and says to run `audit`, which converts it after showing the result (see
   "Migration").

## Implementation notes

Built 2026-10-30. Two changes from the design above:

- **Commands instead of pipelines.** `scripts/spec-fields.sh` takes a command (`status`,
  `outstanding`, `complete`, `in-progress`, `next`, `dependents <id>`, `order`,
  `overlaps [<id>...]`, `check`, `fields`) rather than printing raw rows for each action to filter.
  The actions name a command instead of carrying their own `awk` one-liners, so there is one
  implementation of each query. `SKILL.md` "Spec Files" lists the commands.
- **No `tsort`.** BusyBox, the base of Alpine Linux, has no `tsort`, and macOS `tsort` exits 0 on a
  cycle. `order` sorts the specs itself in `awk` (Kahn's algorithm), breaks ties by lowest id so the
  order is stable, and exits 1 naming the specs on a cycle. The script now needs only `sh`, `awk`,
  `find` and `sort`.

Also added beyond the design: `check` reports duplicate ids across `features/` and `fixes/`, a
`depends_on` naming the spec itself, `merged` without `status: Complete`, quoted values, comments
and flow lists with items. `overlaps` treats a `touches` folder (ending in `/`) as overlapping every
path inside it. `SPEC_DIRS` overrides the folders searched.

**Verification.** `scripts/test-spec-fields.sh` builds sample specs in a temporary folder and runs
38 checks covering every command, an empty `features/` with no `fixes/`, every `check` problem, a
dependency cycle and `SPEC_DIRS`. All pass on macOS (BSD `awk` 20200816, `/bin/sh`), Debian stable
(`dash`, `mawk`) and Alpine (BusyBox `sh` and `awk`), the last two run in Podman containers. Windows
(Git Bash) is not tested.

The trial in "Implementation order" step 5, running `plan` on `docs/plans/GO_PORT_PLAN.md`, has not been
done yet.
