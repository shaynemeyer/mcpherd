# Abandon Action

Stop the loaded feature without merging it, and put the workflow back in a clean state. Nothing
is recorded under `## History` or in `docs/work-log.md`, because nothing was completed.

1. Read `context/current-feature.md` and `context/ai-interaction.md`. If the `**Spec:**` line reads
   `none` and Goals are empty, report that nothing is loaded. Still check for stale `In Progress`
   markers with the in-progress pattern from `SKILL.md`, and offer to reset any you find.
2. Report what the feature left behind:
   - the feature branch, if one exists, and whether it has commits not on `<base>`
     (`git log <base>..<branch> --oneline`) or has been pushed;
   - uncommitted changes (`git status --porcelain`);
   - any open review request for the branch, if the project's CLI can show it.
3. Ask the user what to do with the leftover work. Offer these options, and do nothing to git until
   they choose:
   - **Keep:** leave the branch and changes as they are, for a later attempt.
   - **Discard:** with explicit permission for each step, switch to `<base>`, delete the local branch,
     and delete the remote branch or close the review request. Never discard uncommitted changes
     without showing them first.
4. Ask whether the attempt taught anything worth keeping, such as a wrong assumption in the spec or
   a constraint found in the code. If so, add it to the spec's `## Notes` as
   `**Abandoned YYYY-MM-DD:** <reason and findings>`, so the next attempt starts with it.
5. Reset the spec's frontmatter to `status: Not Started`.
6. Reset `context/current-feature.md`: H1 back to `# Current Feature`, `**Spec:**` back to `none`,
   Status to "Not Started", and Goals and Notes cleared back to their placeholder comments. Leave
   `## History` unchanged.
7. Report what was reset and what happened to the branch. The spec and `current-feature.md` changes
   are left uncommitted; the user decides when to commit them.
