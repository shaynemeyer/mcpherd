# Complete Action

Read the base branch, remote, review mechanism and branch naming from `context/ai-interaction.md`
(`setup` records them under "Remote and Review"; a project set up earlier may keep them under
another heading in that file). Below, `<base>` is the base branch and "review
request" means whatever the project uses: a GitLab merge request, a GitHub pull request, or another
review tool. If the file doesn't say, ask before any git step rather than guessing.

The steps take one of two paths:

- **Reviewed base** (the default, and required when the base branch is protected, i.e. changes
  reach it only through a review request merged by a person): completion goes through two review
  requests, the feature request and then a completion request on a chore branch. This action never
  merges and never pushes to `<base>`.
- **Direct merge** (only when `context/ai-interaction.md` says changes may be merged into `<base>`
  without review): in step 4, merge the feature branch into `<base>` locally instead of opening a
  request, skip the waits in steps 5 and 12, and make the step 11 commit on `<base>` (or the chore
  branch, if the project's convention says so).

Every git step below requires explicit user permission before running, and the build must pass
first. Confirm before starting. If the agent's own permissions block `git push`, give the user the
exact command instead of working around it.

## Phase 1: the feature review request

Find the spec from the `**Spec:**` line of `context/current-feature.md`.

1. Verify the project's build and tests pass, using the commands in `context/ai-interaction.md`.
   For a change confined to docs, run the checks that cover anything touched, and say which ones
   were skipped and why.
2. Stage the feature's changes by name, not with `git add .` or `-A`, and commit on the feature
   branch. Write the commit message and the review request copy as "Commit Messages and Review
   Requests" in `context/ai-interaction.md` describes, and show both when asking permission to
   commit.
3. Push the feature branch with `git push -u <remote> <branch>` (usually `origin`).
4. Open a review request into `<base>` using the CLI named in `context/ai-interaction.md` (e.g.
   `glab mr create` or `gh pr create`), with the title and description approved in step 2. If no
   CLI is available, give the user the URL that the push printed, along with the copy to paste.
5. **Stop.** A person merges the request. Wait for the user to confirm it merged, then
   `git switch <base> && git pull --ff-only` and read the merge commit's sha with
   `git log --merges -1 --format=%h`. If the project squashes or rebases on merge, there is no merge
   commit: use `git log -1 --format=%h` on `<base>` instead.

## Phase 2: the completion review request

6. Create the completion branch from the updated `<base>`, named per the project's convention
   (default `chore/feature-<nn>-completion`).
7. Mark the spec complete: set the `**Status:**` line under the H1 of the spec named on the
   `**Spec:**` line to `Complete — merged YYYY-MM-DD (<merge commit sha>)`. It will read
   `In Progress` at this point, because `start` wrote that. Replace the whole line rather than
   appending to it.
8. Roll the history forward, in this order. The move must happen before the new entry is written,
   or the archive ends up out of order:
   - If `## History` in `context/current-feature.md` already holds an entry, append it to the END
     of `context/feature-history.md` (the archive, oldest to newest).
   - Then reset `context/current-feature.md`:
     - Change the H1 back to `# Current Feature` and the `**Spec:**` line back to `none`.
     - Set Status back to "Not Started".
     - Clear the Goals and Notes sections, keeping the placeholder comments.
     - Write this feature's summary as the **only** entry under `## History`.
9. Append this feature's summary to `docs/work-log.md`, the durable record of what was built and
   why. It is kept in the repo rather than only in the chat that produced it. Newest entries go at
   the END, so the file reads oldest to newest like `context/feature-history.md`.

   Write one `## nn-name — Title` section per feature, with a
   `**Branch:** … · **Merged:** YYYY-MM-DD (<sha>)` line under it. Cover, in whatever subheadings the
   work warrants:
   - what was built, and the decisions that were judgement calls rather than the obvious choice;
   - anything that deviates from the spec, and why;
   - bugs found during the work that the build could not see, and what now pins them;
   - what was verified, against what (test counts, and anything checked against a real external
     system or dependency rather than a mock or local stand-in);
   - anything left open for the user's judgement.

   **Make it longer and more specific than the `## History` entry**, which is a paragraph for
   orientation. This is the entry someone reads in six months to find out why a field is shaped the
   way it is. Do not restate the spec: that file is still in `context/features/` and is linked by
   name.

   If `docs/work-log.md` does not exist, create it with a `# Work Log` H1.

10. Carry this feature's findings forward into every unfinished spec, since any of them may be the
    one worked next. This is the forward half of workflow step 2 in `context/ai-interaction.md`:
    that step has the *next* feature read what its dependencies turned up, and this step makes sure
    there is something written down to read. A spec is written before the work, so without this
    step a later spec still describes a world this feature has already changed.

    - **Check every unfinished spec, not only the dependents.** Any outstanding spec could be the
      next one worked, so all of them are in scope. List every spec in `context/features/` and
      `context/fixes/` whose status line is not `Complete` (outstanding pattern from `SKILL.md`;
      `In Progress` and `Not Started` both count), and check each one against what this feature
      changed or learned. Start with the dependents, whose `Depends on:` line names this feature by
      filename, by number, or inside a range such as "features 91–99". The line has no single
      format, so read it rather than grepping for the filename. Then go through the rest: a spec
      with no declared dependency is still affected if it relies on something this feature changed,
      such as a file, an interface or data shape, a config key, a command, or a decision it
      superseded.
      If a spec turns out to depend on this feature without saying so, add this feature to its
      `Depends on:` line as well.
    - **Decide what carries.** Use the work-log entry from step 9 as the source, not the spec.
      Carry what a later feature would get wrong without being told: deviations from this spec,
      renamed or reshaped interfaces, bugs found and how they are now pinned, constraints
      discovered, superseded decisions, and anything left unverified that a later spec will be the
      first to exercise. Leave out what a given spec does not touch.
    - **Write it into each affected spec.** Add a bullet under its `## Notes` section headed
      `**What \`<nn>\` turned up that this feature must carry**`, naming the work-log entry as the
      source. Notes and `Touches` may be updated without asking. A
      finding that changes a spec's Goals, Acceptance Criteria or Non-goals is a change to
      what will be built: propose the edit, get the user's agreement, then make it in place with
      `(updated YYYY-MM-DD after <nn>)`. Never change another spec's `**Status:**` line here.
    - **Source plans and registers.** If the plan document this feature came from (named in its
      spec's `## Context` section), or any register the project keeps of open items, describes
      something this feature changed or closed, update that too.
    - **Completed specs are not edited.** If a `Complete` spec is now wrong, report it and ask
      whether it should reopen, instead of rewriting it quietly.
    - **Report what carried.** List each spec touched and the gist of what was added. If nothing
      needed carrying, say so explicitly rather than adding empty notes.

11. Commit the status line, the reset, the work log and the forward notes from step 10 together,
    following the commit convention in `context/ai-interaction.md` (default subject:
    `chore: reset current-feature.md after completing [feature]`).
12. Push the chore branch and open its review request, as in steps 3–4, writing its copy the same
    way. List the specs that step 10 changed in the description, since a reviewer merging "a reset"
    would not otherwise look at them. **Stop** again until a person merges it.
13. After both requests have merged, `git switch <base> && git pull --ff-only`. Then ask before
    deleting the local feature and chore branches, and delete them from the remote if the review
    tool did not already remove them on merge.
