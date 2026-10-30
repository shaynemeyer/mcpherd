# Parallel Action

Implement several independent specs at the same time. Each spec runs in a sub-agent with its own
context window, on its own branch, in its own git worktree under `.worktrees/`. Specs that depend
on unfinished work still run one after another, through `load` and `start`.

Usage: `parallel <nn-name> <nn-name> ...`. With no list, offer every spec that qualifies, up to
the **batch size limit of 3**.

Who does what:

- **The user** approves the batch, pushes each branch and has each review request merged.
- **The main session** checks and sets up the batch, creates every branch and worktree, starts
  the sub-agents, reviews their work, and is the only one that edits the shared files
  (`context/current-feature.md`, `context/feature-history.md`, `docs/work-log.md` and the spec
  files). It runs every git command that touches shared state, one at a time.
- **Each sub-agent** works only inside its own worktree and commits only to its own branch.
  Nothing else: no worktrees, pushes, merges or branch deletions.

Only step 3 runs in parallel. Commands written `spec-fields.sh` are `scripts/spec-fields.sh` in
this skill's directory, run from the repository root (see "Spec Files" in `SKILL.md`). `<base>`,
`<remote>` and the branch naming come from "Remote and Review" in `context/ai-interaction.md`; ask
if they aren't recorded.

## Which specs qualify

A spec joins the batch only when all of these hold:

1. Every id in its `depends_on` is `Complete` (`spec-fields.sh status`). This is the test `next`
   uses. Its own `status` is `Not Started`, or `In Progress` only as a stale marker that the user
   agrees to reset (as `load` step 3 does).
2. No spec in the batch depends on another spec in the batch, directly or through a chain. Check 1
   already rules this out for direct dependencies; `spec-fields.sh order` shows chains.
3. No two specs in the batch have overlapping `touches`: `spec-fields.sh overlaps <id> <id> ...`
   prints nothing. A folder in `touches` overlaps every path inside it. A spec whose `touches` is
   `[]` can't be checked, so it doesn't qualify until the audit in check 4 fills it.
4. It passes the single-spec audit (`actions/audit.md` steps 1 and 3–5), as `load` step 4 runs
   it. That includes `spec-fields.sh check`, so an old-format or malformed spec is excluded until
   `audit` fixes it. Changes to Goals still need the user's agreement.

Run check 4 last, on the specs that passed checks 1–3, and run check 3 again afterwards, since the
audit can change `touches`. Specs that fail a check are left out, and the report says which check
and why. When more than 3 qualify, offer the lowest-numbered 3 and list the rest.

## Steps

### 1. Pick and check

1. Read `context/current-feature.md`, `context/ai-interaction.md`,
   `context/coding-standards.md` and `context/testing-instructions.md`.
2. Refuse to start when a single feature is loaded (the `**Spec:**` line names a spec) or a batch
   is already active (`## Batch` exists). Say which, and suggest `complete` or `abandon` first.
3. Read "Parallel Safety" in `context/testing-instructions.md`.
   - It says the suite can't run in several worktrees at once: stop and report that the batch
     can't run, with the reason it gives.
   - The section is missing or says it's unknown: say so, and ask the user to confirm the
     checks can run side by side (no fixed ports, shared databases, shared temp files) before
     going on. Offer to record the answer in that section.
4. Apply the checks in "Which specs qualify" to the requested specs, or to every outstanding spec
   when none were named.
5. Show the proposed batch: each spec with the branch and worktree it will use (see step 2), the
   excluded specs with reasons, and the base branch. Say that approving the batch also lets each
   sub-agent commit to its own branch once its checks pass, and that nothing is pushed without the
   user. Wait for approval.

### 2. Set up

All of this runs in the main session, one command at a time. Each git step follows "When Stuck".
Any failure is reported before a sub-agent starts.

1. Check that the main working tree is clean (`git status --porcelain`). If it isn't, stop and
   show the changes; don't stash, discard or commit them.
2. Update the base branch: `git switch <base> && git pull --ff-only`. Record its sha
   (`git rev-parse --short HEAD`) as the base commit.
3. Check that `.worktrees/` is ignored: `git check-ignore -q .worktrees/x`. If it isn't, add
   `.worktrees/` to the root `.gitignore` under a `# Parallel worktrees` comment, then stop: that
   change has to be committed and merged first, so the worktrees never show up as untracked files.
4. For each spec, one at a time:
   - Choose its branch name from the naming convention in `context/ai-interaction.md` (for example
     `feature/<nn-name>` or `fix/<nn-name>`) and its worktree path, `.worktrees/<nn-name>`.
   - Check that neither exists: `git rev-parse --verify --quiet refs/heads/<branch>` prints
     nothing, and the path is absent. If either exists, stop and report it. It is usually left
     over from an earlier run; the user decides whether to remove it.
   - Create both: `git worktree add .worktrees/<nn-name> -b <branch> <base sha>`.
   - Set `status: In Progress` in the spec's frontmatter, in the main checkout.
5. Check that `git worktree list` shows every new worktree on its branch at the base sha.
6. Record the batch in `context/current-feature.md`, as "Batch record" below describes, with
   every spec in state `running`.

These edits to `context/` stay uncommitted in the main checkout. `complete` commits them with the
first completion (see "Completing batch specs"), and the sub-agents never touch those files, so
pulling `<base>` in the meantime doesn't conflict with them.

### 3. Start sub-agents

If the tool supports sub-agents, start one per spec, all at once. If it doesn't, see "Fallback".

Each brief contains:

- the spec's path, its branch name, and its worktree path, which already exists with the branch
  checked out. Paths in the brief are absolute, so the sub-agent can't mistake the main checkout
  for its worktree;
- the paths of `context/ai-interaction.md`, `context/coding-standards.md` and
  `context/testing-instructions.md`, to read first;
- the `docs/work-log.md` entries for the spec's dependencies, or their headings;
- the task: implement the spec's Goals one at a time inside the worktree, as `actions/start.md`
  steps 6–7 describe, running the build and targeted tests after each goal and the full set of
  checks at the end. There is no approval step for the approach: the spec is the approach, and a
  choice the spec leaves open is made and reported;
- the file rules: work only inside the worktree. Don't edit `context/current-feature.md`,
  `context/feature-history.md`, `docs/work-log.md`, or any spec file, its own included. The main
  session keeps uncommitted state in those files, and a change to them on the branch would block
  the next `git pull`. Report needed spec changes (`touches`, deviations) instead;
- the commit rule: commit to its branch only when the build, lint and tests pass, with messages
  following "Commit Messages and Review Requests" in `context/ai-interaction.md`, including the
  no-attribution rule. Stage files by name, and leave review output out of every commit, as
  "Review Output" there describes;
- the git rules in "Git in a shared repository" below, copied in full;
- the stuck rule, "When Stuck" in `context/ai-interaction.md`: after two failed attempts at a task,
  STOP and REPORT instead of trying again. Don't revert or clean up; leave the changes in the
  worktree, uncommitted.

Each sub-agent ends with one of two reports:

- **Finished:** what it built, and any decision that wasn't the obvious choice; anything that
  deviates from the spec; the checks it ran, with their results; spec changes it needs (such as
  paths to add to `touches`); anything left open; its commits (sha and subject); and proposed
  review request copy following "Commit Messages and Review Requests".
- **Blocked:** the report "When Stuck" describes. A blocked sub-agent doesn't commit.

While any sub-agent is still running, the main session uses only read-only git commands (`status`,
`diff`, `log`, `worktree list`).

### 4. Collect and review

As each sub-agent finishes:

1. Check its worktree: `git -C <worktree> status --porcelain` and
   `git -C <worktree> log <base sha>..HEAD --oneline`. Compare them with the report.
2. For a finished spec, run `actions/review.md` against that spec and its worktree. Run the
   project's checks in the worktree again rather than trusting the report. Apply spec changes it
   reported (`touches`, Notes) in the main checkout. Set its state to `review`.
3. For a blocked spec, or a sub-agent that crashed, ran out of context or returned no report, set
   its state to `blocked` and keep its worktree and branch as they are. Describe what the worktree
   shows was done.

Present all results together: each spec's verdict, issues, deviations and open items, and each
blocked report. Then follow "Failure handling" for the blocked ones.

Fixes the review asks for are made as new commits on that branch, in its worktree, by the main
session or a new sub-agent with the review in its brief. Set the state back to `running` while
they're made, and review again. The two-attempt rule applies to the fixes too.

### 5. Push and open review requests

For each spec the user approves:

1. Ask the user to push it, giving the exact command: `git push -u <remote> <branch>`, run from the
   worktree or the main checkout. Pushing is the user's step, or the main session's with explicit
   permission for each push.
2. Give the review request title and description to paste (or the CLI command from
   `context/ai-interaction.md`), based on the sub-agent's copy and corrected against the diff.
3. Set its state to `approved`.

### 6. Complete one at a time

Specs complete in the order their review requests merge, each with its own completion request, as
"Completing batch specs" below describes. When the user says a request merged, set that spec's
state to `merged` and run `complete <nn-name>`.

After each completion request merges, and before the next spec completes:

1. Bring every remaining batch branch up to date by merging the updated `<base>` into it, in its
   worktree: `git -C <worktree> merge <base>`. Don't rebase: the branches are already pushed, and
   a rebase would need a force push. If a merge conflicts, stop and report the conflicting files
   for that branch; don't resolve them silently. Run the checks in that worktree after a clean
   merge, and ask the user to push each updated branch.
2. `complete` step 10 carries the merged feature's findings into the remaining specs. These specs
   were written before their siblings finished, so check whether a remaining branch already
   conflicts with what was carried, and report it as a review issue on that branch.

### 7. Clean up

After every spec in the batch has completed or been dropped:

1. For each worktree, ask before removing it: `git worktree remove .worktrees/<nn-name>`. If git
   refuses because the worktree has changes, show them and leave it.
2. Ask before deleting each local branch (`git branch -d <branch>`), and remind the user to delete
   the remote branches if the review tool didn't.
3. Check that `git worktree list` shows only the main checkout, or report what is left.
4. Make sure `## Batch` is gone from `context/current-feature.md` and the file is back to its
   no-feature state (see "Batch record").

## Git in a shared repository

All worktrees share one `.git` folder. Each worktree has its own index, `HEAD` and branch, so
commits on different branches in different worktrees rarely block each other. What collides is a
command that writes a file every worktree shares. These rules go into every sub-agent brief:

- **Allowed:** `git status`, `git diff`, `git log`, `git add` and `git commit`, inside its own
  worktree only.
- **Commit without automatic cleanup:** run commits as
  `git -c gc.auto=0 -c maintenance.auto=false commit ...`. Otherwise git can start `gc` or
  maintenance after a commit, which locks and repacks the shared object store. The `-c` flags apply
  to that one command and don't change git config.
- **Not allowed:** `stash` (one `refs/stash` is shared by every worktree), `fetch`, `pull`, `push`,
  `merge`, `rebase`, `reset`, `checkout` or `switch` of another branch, `branch -d`/`-D`, `gc`,
  `config`, `pack-refs`, and `worktree add`/`remove`.
- **Never delete a `.lock` file.** It can belong to a git command that is still running, and
  removing it can corrupt the repository.
- **Lock errors follow "When Stuck".** The failed command is the first attempt. The second is one
  retry after waiting a few seconds. If that fails too, STOP and REPORT, leaving the changes
  uncommitted.

The main session runs every command that touches shared state (creating worktrees, `pull`, merging
`<base>` into branches, removing worktrees) one at a time.

## Batch record

While a batch is active, `context/current-feature.md` looks like this:

```markdown
# Current Feature: Batch (04, 05, 06)

**Spec:** batch

## Status

In Progress

## Goals

### 04-name — Title

- <the spec's Goals, then its Acceptance Criteria>

### 05-name — Title

- ...

## Notes

### 04-name — Title

- <the spec's Notes and Non-goals>

## Batch

**Base:** main @ <base sha>

| Spec | Branch | Worktree | State |
| --- | --- | --- | --- |
| context/features/04-name.md | feature/04-name | .worktrees/04-name | running |
| context/features/05-name.md | feature/05-name | .worktrees/05-name | review |

## History

<unchanged>
```

- `**Spec:** batch` tells every other action to read the specs from `## Batch`.
- `## Batch` goes between Notes and History. It exists only during a batch.
- **States:** `running` (a sub-agent or the main session is working on it), `blocked` (stopped,
  waiting for the user), `review` (committed and reviewed), `approved` (the user approved it and it
  is pushed), `merged` (its feature review request merged; `complete` is next), `dropped`.
  The usual path is `running` → `review` → `approved` → `merged`. `blocked` goes back to `running`
  on a retry, and `review` goes back to `running` while fixes are made.
- A spec leaves the table when `complete` finishes it or it is dropped. Its Goals and Notes
  subsections go with it, and the H1 lists the ids that remain.
- When the last spec leaves, remove `## Batch` and reset the file as `complete` step 8 does: H1
  `# Current Feature`, `**Spec:** none`, Status "Not Started", Goals and Notes back to their
  placeholder comments. Leave `## History` alone.

## Completing batch specs

`complete <nn-name>` works on a batch spec with these differences:

- **Phase 1 is already done** by steps 4–5 here: the sub-agent committed, the review passed, and
  the user pushed and opened the review request. `complete` starts at step 5, waiting for the merge.
- **Step 8** writes this spec's History entry as usual (moving the previous one to
  `context/feature-history.md` first), so `## History` gets one entry per completion, in merge
  order. Instead of resetting the whole file, it removes this spec from the batch record, as
  above.
- **Step 11** stages `context/current-feature.md` and every spec file changed in the main checkout,
  including the `status: In Progress` lines that step 2 wrote for the remaining batch specs. The
  completion commit then holds the batch state, and no uncommitted state is left in files a later
  pull would change.
- **Step 13** leaves this spec's worktree and local feature branch for step 7 here; the chore
  branch is deleted as usual. Don't switch the main checkout to the next chore branch until the
  current completion request has merged.

## Failure handling

### A sub-agent gets stuck

A sub-agent can't ask the user anything mid-run. Its brief carries "When Stuck": after two failed
attempts, it STOPS and ends with a blocked report, leaving its changes uncommitted in the worktree.

The main session then:

1. Sets the spec's state to `blocked`.
2. Keeps the worktree and branch as they are.
3. Shows the blocked report alongside the other results in step 4. It doesn't restart the
   sub-agent with the same brief.
4. Acts on the user's choice:
   - **Retry:** start a new sub-agent with the blocked report and the user's new information added
     to the brief, in the same worktree. Set the state to `running`. The new sub-agent gets its
     own two attempts.
   - **Finish in the main session:** pick up the work in that worktree, with the same rule: after
     two more failed attempts, STOP and REPORT to the user. Set the state to `running`.
   - **Drop:** see "Dropped spec".

A sub-agent that fails another way (crashes, runs out of context, or returns no report) is
handled the same way: state `blocked`, worktree kept, the user chooses.

### Dropped spec

Follow `actions/abandon.md` for that spec, as its "Batch specs" section describes: report what the
worktree and branch hold, ask before removing the worktree or deleting the branch, offer to record
what the attempt taught in the spec's Notes, set its `status` back to `Not Started`, and remove it
from the batch record.

## Fallback

If the tool can't run sub-agents, work through the batch one spec at a time in the main session,
with the same steps: the same worktrees and branches, the same file and git rules, and the same
commit permission. Finish one spec's implementation and step 4 review before starting the next.

## Report

At the end of each step that waits on the user, report briefly: each spec with its state, branch
and verdict; anything blocked, with its question; and the next action the user needs to take.
