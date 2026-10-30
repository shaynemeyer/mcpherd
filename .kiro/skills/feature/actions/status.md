# Status Action

Read-only. Never modifies a file, never touches git state, never asks for permission.

1. Read `context/current-feature.md` — the H1 and `## Status`, plus the `## History` entry (the
   previously completed feature), and `## Batch` if it exists.
2. Count progress across specs with `scripts/spec-fields.sh` (see the Spec Files section of
   `SKILL.md`): `status` for the totals, `in-progress`, and `next`.
   - in progress: at most one, and it should be the spec on the `**Spec:**` line of
     `context/current-feature.md`. During a batch, the in-progress specs should be exactly the
     ones listed under `## Batch` (a `merged` row may already show `Complete`). More than one
     outside a batch, or one that disagrees with that line or table, is a stale
     marker from an abandoned attempt: report it as an anomaly rather than quietly fixing it, since
     it usually means a branch was left behind too. Suggest `abandon` or `load` to clear it.
   - next up: the id `next` prints. If it prints nothing while specs are outstanding, every
     remaining spec waits on an unfinished one; say which.
   - problems: run `check`. Report its findings in one line (for example "2 specs need `audit`"),
     without fixing them. Old-format specs and dependency cycles go here.
3. Report git state: current branch, uncommitted change count, commits not pushed to its upstream.
   Run `git worktree list` too. During a batch, check that it matches `## Batch`: every row has
   its worktree on its branch, and no worktree under `.worktrees/` is missing from the table.
   Outside a batch, any worktree under `.worktrees/` is a leftover from an interrupted run. Report
   mismatches and leftovers as anomalies.
4. Report gate state using the commands in `context/ai-interaction.md`. Run them only if they are
   fast; if a gate is slow or needs a service that is not running, say it was not checked rather
   than reporting a guess.
5. Note anything blocked or awaiting a decision — a dirty tree, an unmerged branch, a spec loaded
   but not started, gates failing.

## Output Format

Lead with the answer, then the detail. Keep it to a handful of lines — this action is used to
orient quickly, so a long report defeats it.

```
Current:   <feature name and status, or "nothing loaded", or "batch of <n>">
Progress:  <n> of <total> complete — next up <nn-name>
Specs:     <"ok", or what check found, e.g. "2 need audit (old format)">
Git:       <branch>, <clean | n uncommitted>, <n unpushed>
Gates:     <the project's checks, e.g. build / lint / tests, or "not checked (reason)">
Previous:  <feature from History>
```

During a batch, follow `Current:` with one line per batch spec:

```
  <nn-name>  <state>  <branch>  <n commits ahead of base, clean | n uncommitted>
```

Run the gates in the main checkout only; per-worktree checks belong to `review <nn-name>`.

Follow with a line on what to do next, and anything waiting on the user. If everything is clean
and nothing is loaded, say so plainly instead of padding the report.
