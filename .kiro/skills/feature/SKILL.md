---
name: feature
description: Manage the current feature workflow — set up a project's context files, split a plan into feature specs, report status, audit specs against the code, load a spec, start implementation, review, test, explain, complete, or abandon a feature. Use when the user asks to set up the feature workflow in a project, to turn a plan document into specs, for feature status or progress, to audit or check specs for drift, or to load/start/review/test/explain/complete/abandon a feature or fix, or refers to the feature lifecycle tracked in context/current-feature.md.
---

# Feature Workflow

Manages the full lifecycle of a feature from spec to merge. State is tracked in
`context/current-feature.md` — read that file at the start of every action except `setup`, which
creates it.

## Working File

`context/current-feature.md` has these parts:

- `# Current Feature` — H1 heading, includes the feature name when a feature is active
- `**Spec:**` — the line under the H1: the path of the loaded spec file, or `none`. `load` writes it;
  `start`, `review`, `complete` and `abandon` read it to find the spec
- `## Status` — Not Started | In Progress | Complete. `complete` resets this to "Not Started" and
  records the feature under History, so "Complete" is only ever a transient value
- `## Goals` — bullet points of what success looks like
- `## Notes` — additional context, constraints, or details from the spec
- `## History` — the previously completed feature: the one finished immediately before whatever is
  currently loaded. Exactly one entry. `complete` moves any prior entry to
  `context/feature-history.md` (the archive, oldest to newest) before writing the new one, so this
  section never accumulates

## Work Log

`docs/work-log.md` is the durable record of completed work: one `##` section per feature, oldest to
newest, written when the work is finished and summarized. `complete` commits it, in its completion
merge request, step 11. Write the entry as soon as the work is done and reported, rather than
waiting: the reasoning behind a decision is cheapest to record while it is still in view.

It is deliberately not the same thing as the two files above. `## History` in
`context/current-feature.md` is one paragraph for orientation and holds exactly one entry;
`docs/work-log.md` is long-form and keeps everything. Neither is loaded automatically, so an entry
here is written for someone arriving cold.

## Spec Files

Feature specs live in `context/features/{nn-name}.md` (fixes in `context/fixes/`), numbered in
dependency order. Every spec follows `templates/spec.md`. Each carries a status line directly
under its H1:

```markdown
# Feature Title

**Status:** Not Started
```

Three values are used: `Not Started`, `In Progress` which `start` writes, and
`Complete — merged YYYY-MM-DD (<sha>)` which `complete` writes.

**`In Progress` has a single holder:** the spec named on the `**Spec:**` line of
`context/current-feature.md`. Any other spec marked `In Progress` is stale, left by an attempt that
was abandoned without running `abandon`. `load` resets stale markers, and `status` reports them.

To list specs by status, use these patterns. They are anchored to the status line so a spec that
mentions "Complete" in prose isn't miscounted. They search the folders recursively rather than with
a `*.md` glob, because zsh aborts on a glob that matches nothing, and `context/fixes/` may be empty
or missing.

- outstanding (Not Started or In Progress):
  `grep -rL --include='*.md' '^\*\*Status:\*\*.*Complete' context/features context/fixes 2>/dev/null`
- complete:
  `grep -rl --include='*.md' '^\*\*Status:\*\*.*Complete' context/features context/fixes 2>/dev/null`
- in progress:
  `grep -rl --include='*.md' '^\*\*Status:\*\*.*In Progress' context/features context/fixes 2>/dev/null`

Completed specs stay in place rather than moving to an archive folder: later features keep building
on them (a spec that sets up core types or configuration is referenced by most of what follows), and
each spec's `Depends on:` line names siblings by filename.

## Actions

The user names one action. Determine which from their request.

| Action     | Description                                               |
| ---------- | --------------------------------------------------------- |
| `setup`    | Create the `context/` files from `templates/` — one-time; skips if the project is already set up |
| `plan`     | Split a plan document into numbered specs, activating none |
| `status`   | Report where things stand — read-only, changes nothing    |
| `audit`    | Check unfinished specs against the code and each other; fix drift in spec files only (`audit <nn-name>` for one) |
| `load`     | Audit, then load a feature spec, or write a spec from an inline description and load it |
| `start`    | Prepare the branch, confirm the approach, implement        |
| `review`   | Check the diff against the spec and standards; give a verdict |
| `test`     | Write or verify tests for the feature's new logic          |
| `explain`  | Document what changed and why                             |
| `complete` | Commit, push, open review requests for a person to merge, reset, log, carry findings into unfinished specs |
| `abandon`  | Stop the loaded feature without merging: reset its spec and `current-feature.md`, and deal with its branch |

Before executing, read the matching instruction file for the full steps: `actions/{action}.md` in
this skill's directory. Paths in the action files that start `actions/` or `templates/` are relative
to that directory, wherever the skill is installed (for example `.kiro/skills/feature/` or
`.claude/skills/feature/`, or one symlinked to the other).

If the user did not specify an action, list the options above and ask which they want.

## Templates

`templates/` in this skill's directory holds:

- `ai-interaction.md`, `project-overview.md`, `current-feature.md`, and `README.md`: the starting
  files `setup` copies into `context/`. They are deliberately generic; `setup` tailors them to
  repository evidence.
- `spec.md`: the structure of every feature and fix spec. `plan` and `load` create specs from it;
  `audit` and `complete` rely on its section names.

`templates/ai-interaction.md` starts with a marker comment, `<!-- feature-skill: untailored -->`.
`setup` removes it while tailoring the copy in `context/`. A `context/ai-interaction.md` that exists,
has content, and lacks the marker means the project is already set up, so `setup` stops. Keep the
marker as the first line of the template when editing it.

## Constraints

- Read `context/ai-interaction.md` at the start of any action that runs commands or touches git
  (`setup` excepted: it checks that file for the marker and may be what creates it).
  It is the source of truth for workflow, branch naming, commit format, and dev commands.
  `context/coding-standards.md` is the source of truth for code conventions. Do not hardcode
  stack-specific commands or assumptions here.
- Never commit, merge, push, or delete a branch without explicit permission, and never before the
  build passes. This overrides any looser wording in the action files.
- After two failed attempts at the same task, STOP and REPORT, as "When Stuck" in
  `context/ai-interaction.md` describes. This applies in every action, to the main session and to
  every sub-agent, and every sub-agent brief must include it.
