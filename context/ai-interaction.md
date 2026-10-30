## Communication

- Be concise and direct.
- Explain non-obvious decisions briefly.
- Ask before large refactors, architectural changes, or file deletion.
- Do not add features outside the active specification.

## Workflow

1. Document the active work in `context/current-feature.md`.
2. Create a branch from `main` using the branch naming under "Remote and Review".
3. Implement only the documented goals.
4. Run the validation commands below, targeted tests first, then the full set. Add meaningful tests
   for new logic using the standard `testing` package and the patterns already in the repository.
5. Iterate on verified failures; do not make random changes.
6. Obtain explicit permission before committing. Never add AI attribution to commit messages or
   review requests (pull request titles and descriptions): no `Co-Authored-By` trailers for an AI
   model or tool, no "Generated with" lines, and no mention of the model or agent that wrote the
   change. They describe the change only.
7. Obtain explicit permission before merging or pushing.
8. Obtain explicit permission before deleting local or remote branches.
9. Review changed behavior for correctness, security, performance, and consistency.
10. Mark the source spec complete and roll feature history forward only after the merge succeeds.
11. After the merge, record the work in `docs/work-log.md`: one `## nn-name — Title` section per
    feature, oldest to newest. Cover decisions, deviations, bugs the build could not see,
    verification, and anything open for judgement. `complete` writes it.

## Validation Commands

No Go code exists yet (status: planning). These are the commands `docs/GO_PORT_PLAN.md` Phase 0
plans for CI. They have not been run against real code; confirm them once Phase 0 lands and update
this section.

- Format check: `gofmt -l .` (must print nothing)
- Vet: `go vet ./...`
- Build: `go build ./...`
- Tests: `go test ./...`; targeted: `go test ./internal/<package>/...`
- Race check for concurrent code (MCP client, abort listener): `go test -race ./...`

Installed locally: Go 1.27.3. No linter beyond `go vet` is configured or installed
(`golangci-lint` and `staticcheck` are absent). For a docs-only change, no Go checks apply; say so
when reporting.

## Remote and Review

- Remote and base branch: `origin` (`git@github.com:shaynemeyer/mcpherd.git`); features merge into
  `main`.
- Review mechanism: GitHub pull request. Treat `main` as protected: changes reach it only through a
  pull request merged by a person, and nothing is pushed to `main` directly.
- CLI for opening review requests: none installed (`gh` is absent). Push the branch and give the
  user the pull request URL from the push output, with the title and description to paste.
- Merge style: not established (the history is a single "initial commit"). Ask before the first
  `complete`, and record the answer here.
- Branch naming: `feature/<nn-name>`, `fix/<nn-name>`, and `chore/feature-<nn>-completion` for
  completion branches.

`complete` reads this section. If a line can't be filled from repository evidence, ask the user.

## Commit Messages and Review Requests

When asking permission to commit, show the proposed commit message and the review request copy
together, so both can be approved at once.

- **Commit message:** a short imperative subject line (e.g. `Add NDJSON chunk parser for Ollama
  streaming`) that says what changed, then a body after a blank line that summarizes the work. Cover what changed and why, any decision that
  wasn't the obvious choice, and anything a reviewer would otherwise have to work out from the diff.
  Keep it short: a few lines or bullets, not a file-by-file list.
- **Review request copy:** a ready-to-paste title and description for the pull request. The
  description covers a summary of the change, what was verified and how (commands run, tests
  added), and anything left open or needing the reviewer's attention. Link the spec it implements.
- Describe the work actually done, as shown by the diff, rather than restating the spec.
- The no-attribution rule in Workflow step 6 applies to both.

## Review Output

Review results, such as semantic review documents and verdicts written by review tools or
sub-agents, can contain things that must not be committed: secrets or tokens found in the code,
security weaknesses not yet fixed, internal hostnames or paths, personal data from test fixtures,
or excerpts of private files. Keep them out of source control.

- Review output folder: `.reviews/` at the repository root. It is listed in `.gitignore`.
- Write review documents only to that folder, or outside the repository. If a review tool picks its
  own location inside the repository, add that path to `.gitignore` before running it.
- Before every commit, check the staged files (`git diff --cached --name-only`) and leave out any
  review output. If review output is already tracked, stop and tell the user rather than removing
  it from history yourself.
- Committed files may summarize review results: the work log, specs, commit messages and review
  request descriptions. State what was found and fixed in general terms. Don't copy a secret, an
  unfixed vulnerability's details, or private data into them.

## Project Constraints

- mcpherd writes config only inside `~/.config/mcpherd/`, never to another tool's config directory.
  Tests that touch config use a temporary `$HOME`, never the real one.
- Standard library by default. Adding an external module needs the user's agreement; the plan
  expects only `golang.org/x/term` and possibly the MCP go-sdk (decided at Phase 5).
- No deployment yet. Releases (cross-compiled binaries) are planned for Phase 12.

## When Stuck

- After two or three evidence-based attempts fail, stop, summarize the attempts and evidence, and ask a focused question.
- Preserve unrelated changes and existing patterns.
- Keep changes minimal and avoid unrequested refactors.
