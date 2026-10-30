# Review Action

Read-only apart from running the project's checks. Never fixes code; it reports.

1. Read `context/current-feature.md`, the spec named on its `**Spec:**` line,
   `context/coding-standards.md` and `context/ai-interaction.md`.
2. Collect the changes: `git diff <base>...HEAD` for committed work, plus `git diff` and
   `git status --porcelain` for uncommitted and untracked files. `<base>` is the base branch named in
   `context/ai-interaction.md`; ask if it isn't recorded. Read the full changed files where the diff
   alone doesn't show enough context.
3. Run the project's build, lint and test commands from `context/ai-interaction.md`. Record the
   results rather than trusting earlier reports.
4. Check the changes against:
   - **The spec:** each goal and acceptance criterion is met, partly met or missing. Code beyond the
     goals or inside the Non-goals is scope creep. Files changed outside the spec's `touches` are
     worth a note.
   - **Correctness:** logic errors, unhandled errors and edge cases, broken existing behavior.
   - **Security:** input validation at trust boundaries, secrets in code or logs, unsafe use of
     shell, file paths, queries or templates.
   - **Performance:** obviously wasteful work, such as repeated I/O in loops or unbounded growth.
   - **Consistency:** `context/coding-standards.md` and the patterns already in the codebase.
   - **Tests:** new logic has tests that follow `context/testing-instructions.md`.
   - **Leftovers:** debug output, commented-out code, stray TODOs, unrelated changes.

## Output Format

```
Verdict:  <ready to complete | needs changes>
Checks:   <each command and pass/fail>

Goals
- <goal or criterion>: <met | partly met | missing> — <evidence>

Issues
1. [blocking | should fix | nit] path:line — <problem and suggested fix>
```

List blocking issues first. If there are no issues, say so plainly. End with a suggested next step:
`complete` if ready, otherwise the fixes to make.
