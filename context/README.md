# Context

These project context files are listed as always-on context, in the root `AGENTS.md`'s `## Context Files` section if the project has one, and otherwise in `.kiro/steering/project-context.md`. Claude Code reads them through the root `CLAUDE.md`. Subdirectories are read on demand by the feature and research skills.

They were created by the feature skill's `setup` action, which runs once: it skips whenever `ai-interaction.md` here has content and no `<!-- feature-skill: untailored -->` marker. To re-run it, empty or remove that file.

- `project-overview.md` — evidenced project purpose, users, architecture, data, and technology.
- `coding-standards.md` — conventions derived from the repository.
- `ai-interaction.md` — communication, workflow, git, and validation guidance.
- `testing-instructions.md` — meaningful test scope and exact commands.
- `current-feature.md` — active feature state and latest completed feature.
- `feature-history.md` — older completed-feature entries, oldest to newest. Created by the first `complete`, not by `setup`.
- `features/` — feature specifications, following the skill's `templates/spec.md`. The `plan` action can split a plan document into these.
- `fixes/` — fix specifications, same structure.
- `research/` — named research prompts.
- `screenshots/` — optional visual references when relevant.
