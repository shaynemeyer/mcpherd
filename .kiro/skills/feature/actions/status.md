# Status Action

Read-only. Never modifies a file, never touches git state, never asks for permission.

1. Read `context/current-feature.md` — the H1 and `## Status`, plus the `## History` entry (the
   previously completed feature).
2. Count progress across specs in `context/features/` and `context/fixes/`, using the anchored,
   recursive patterns in the Spec Files section of `SKILL.md`. Don't switch to a `*.md` glob or
   drop the anchor: the glob fails in zsh when a folder is empty, and an unanchored pattern
   miscounts specs that mention "Complete" or "In Progress" in prose.
   - in progress: at most one, and it should be the spec on the `**Spec:**` line of
     `context/current-feature.md`. More than one, or one that disagrees with that line, is a stale
     marker from an abandoned attempt: report it as an anomaly rather than quietly fixing it, since
     it usually means a branch was left behind too. Suggest `abandon` or `load` to clear it.
   - the next feature is the lowest-numbered outstanding spec whose dependencies are all complete.
3. Report git state: current branch, uncommitted change count, commits not pushed to its upstream.
4. Report gate state using the commands in `context/ai-interaction.md`. Run them only if they are
   fast; if a gate is slow or needs a service that is not running, say it was not checked rather
   than reporting a guess.
5. Note anything blocked or awaiting a decision — a dirty tree, an unmerged branch, a spec loaded
   but not started, gates failing.

## Output Format

Lead with the answer, then the detail. Keep it to a handful of lines — this action is used to
orient quickly, so a long report defeats it.

```
Current:   <feature name and status, or "nothing loaded">
Progress:  <n> of <total> complete — next up <nn-name>
Git:       <branch>, <clean | n uncommitted>, <n unpushed>
Gates:     <the project's checks, e.g. build / lint / tests, or "not checked (reason)">
Previous:  <feature from History>
```

Follow with a line on what to do next, and anything waiting on the user. If everything is clean
and nothing is loaded, say so plainly instead of padding the report.
