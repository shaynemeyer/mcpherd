<!-- feature-skill: untailored -->

## Communication

- Be concise and direct.
- Explain non-obvious decisions briefly.
- Ask before large refactors, architectural changes, or file deletion.
- Do not add features outside the active specification.

## Workflow

1. Document the active work in `context/current-feature.md`.
2. Create a branch using the repository's established naming convention.
3. Implement only the documented goals.
4. Run the repository's documented targeted tests and required build or validation commands. Add meaningful tests for new logic using existing tools and patterns.
5. Iterate on verified failures; do not make random changes.
6. Obtain explicit permission before committing. Never add AI attribution to commit messages or
   review requests (pull or merge request titles and descriptions): no `Co-Authored-By` trailers
   for an AI model or tool, no "Generated with" lines, and no mention of the model or agent that
   wrote the change. They describe the change only.
7. Obtain explicit permission before merging or pushing.
8. Obtain explicit permission before deleting local or remote branches.
9. Review changed behavior for correctness, security, performance, and consistency.
10. Mark the source spec complete and roll feature history forward only after the merge succeeds.
11. After the merge, record the work in `docs/work-log.md`: one `## nn-name — Title` section per
    feature, oldest to newest. Cover decisions, deviations, bugs the build could not see,
    verification, and anything open for judgement. `complete` writes it.

Replace generic wording in this template during setup with evidence from the target repository: base branch, branch format, commit convention, validation commands, review mechanism, review output folder, and deployment constraints. If no convention exists, state that and ask before consequential operations. Remove the `feature-skill: untailored` marker at the top of the file once tailoring is done.

## Remote and Review

- Remote and base branch: (record the remote name and URL, and the branch features merge into)
- Review mechanism: (GitLab merge request, GitHub pull request, other, or direct merge without review; whether the base branch is protected)
- CLI for opening review requests: (e.g. `glab`, `gh`, or none: use the web UI)
- Merge style: (merge commit, squash, or rebase) and whether source branches are deleted on merge
- Branch naming: (feature, fix and chore prefixes; the completion branch name)

`complete` reads this section. If a line can't be filled from repository evidence, ask the user.

## Commit Messages and Review Requests

When asking permission to commit, show the proposed commit message and the review request copy
together, so both can be approved at once.

- **Commit message:** a subject line that follows the project's commit convention and says what
  changed, then a body after a blank line that summarizes the work. Cover what changed and why,
  any decision that wasn't the obvious choice, and anything a reviewer would otherwise have to
  work out from the diff. Keep it short: a few lines or bullets, not a file-by-file list.
- **Review request copy:** a ready-to-paste title and description for the pull or merge request.
  The description covers a summary of the change, what was verified and how (commands run, tests
  added), and anything left open or needing the reviewer's attention. Link the spec or issue it
  implements. Skip this when the project merges directly without review.
- Describe the work actually done, as shown by the diff, rather than restating the spec.
- The no-attribution rule in Workflow step 6 applies to both.

## Review Output

Review results, such as semantic review documents and verdicts written by review tools or
sub-agents, can contain things that must not be committed: secrets or tokens found in the code,
security weaknesses not yet fixed, internal hostnames or paths, personal data from test fixtures,
or excerpts of private files. Keep them out of source control.

- Review output folder: `.reviews/` at the repository root, unless the project already uses another
  git-ignored folder for this (record it here instead). Confirm the folder is listed in `.gitignore`.
- Write review documents only to that folder, or outside the repository. If a review tool picks its
  own location inside the repository, add that path to `.gitignore` before running it.
- Before every commit, check the staged files (`git diff --cached --name-only`) and leave out any
  review output. If review output is already tracked, stop and tell the user rather than removing
  it from history yourself.
- Committed files may summarize review results: the work log, specs, commit messages and review
  request descriptions. State what was found and fixed in general terms. Don't copy a secret, an
  unfixed vulnerability's details, or private data into them.

## When Stuck

- After two or three evidence-based attempts fail, stop, summarize the attempts and evidence, and ask a focused question.
- Preserve unrelated changes and existing patterns.
- Keep changes minimal and avoid unrequested refactors.