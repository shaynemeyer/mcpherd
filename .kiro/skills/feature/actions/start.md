# Start Action

1. Read `context/current-feature.md` and `context/ai-interaction.md`. If Goals are empty or the
   `**Spec:**` line reads `none`, stop and report that the `load` action must run first.
2. Prepare the base branch, with permission for each git step:
   - Check that the working tree is clean (`git status --porcelain`). If it isn't, stop and show the
     changes. Don't stash, discard or commit them without the user's say.
   - Switch to the base branch named in `context/ai-interaction.md` and update it with
     `git pull --ff-only`. If that fails, stop and report it.
3. Create and check out the feature branch, deriving the name from the H1 heading and following the
   naming convention in `context/ai-interaction.md`.
4. Set Status in `context/current-feature.md` to "In Progress", and set the `**Status:**` line of
   the spec named on the `**Spec:**` line to `In Progress`.
5. Propose the approach before writing code: the goals in the order you'll implement them, the
   files you expect to change (compared with the spec's Touches section), and any decision the spec
   leaves open. Wait for the user to agree or adjust it.
6. Implement the goals one at a time. After each goal, run the project's build and the targeted
   tests from `context/ai-interaction.md` and `context/testing-instructions.md`, and fix failures
   before moving to the next goal. After two failed attempts to fix the same failure, STOP and
   REPORT as "When Stuck" describes; don't move on to the next goal.
7. When all goals are done, run the full set of checks and report what was built, what was verified,
   and anything that deviated from the spec. Suggest `review` next.
