# Feature Skill

A team skill for a spec-driven feature workflow, usable from Kiro, Claude Code or any agent that loads skills, in any project; to share one copy between tools, symlink one skill directory to the other (e.g. `.claude/skills/feature` → `.kiro/skills/feature`). Set the workflow up once with `setup`, split a plan into specs with `plan`, then `load`, `start`, `review`, `test`, `explain`, and `complete` each feature, with `status` to check where things stand, `audit` to check unfinished specs against the code and each other, and `abandon` to stop a feature without merging it. Name the action in the request; with no action named, the skill lists the options and asks. `plan` creates specs without activating any of them; `load` is what activates one, and it audits that spec first.

## Bundled files

The eleven action guides are in `actions/`: `setup.md`, `plan.md`, `status.md`, `audit.md`, `load.md`, `start.md`, `review.md`, `test.md`, `explain.md`, `complete.md`, and `abandon.md`. There are no other actions.

`templates/` holds five files. Setup copies four of them into `context/`: `README.md`, `ai-interaction.md`, `current-feature.md`, and `project-overview.md`. The fifth, `spec.md`, is the structure of every feature and fix spec; `plan` and `load` create specs from it.

`scripts/spec-fields.sh` reads each spec's YAML frontmatter (status, dependencies, and the paths it touches) and answers the questions the actions ask: what is outstanding, what is next, what depends on a spec, the dependency order, which specs overlap, and what is malformed. It needs only `sh`, `awk`, `find` and `sort`. `scripts/test-spec-fields.sh` tests it; it passes on macOS and on Debian and Alpine Linux.

Setup also derives project-specific coding and testing guidance and makes the context files always-on: as a `## Context Files` section in a root `AGENTS.md` if the project has one, so Kiro and Claude Code load the same context, and otherwise as `.kiro/steering/project-context.md` with Kiro workspace-file references. Claude Code reads `CLAUDE.md` rather than `AGENTS.md`, so setup also makes sure a root `CLAUDE.md` pulls the context in, with an `@AGENTS.md` line or `@context/...` lines. Setup runs once per project: it stops without changing anything if `context/ai-interaction.md` has content and no longer carries the `<!-- feature-skill: untailored -->` marker from the template.

Nothing in the skill is tied to a language, framework, host or repository. Project specifics live in the `context/` files that `setup` writes: build, test and lint commands in `ai-interaction.md` and `testing-instructions.md`, conventions in `coding-standards.md`, and the base branch, remote and review mechanism (GitLab MR, GitHub PR or direct merge) under "Remote and Review" in `ai-interaction.md`, which `complete` and `explain` read. Fixed conventions the skill does impose: specs in `context/features/` and `context/fixes/` with `nn-name` filenames, YAML frontmatter (`status`, `merged`, `depends_on`, `touches`) and the sections in `templates/spec.md`; a `**Spec:**` line in `context/current-feature.md` naming the loaded spec; and the work log at `docs/work-log.md`.

See `SKILL.md` for state semantics, dispatch rules, and git safety constraints.
