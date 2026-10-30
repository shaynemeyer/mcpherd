# mcpherd

A terminal MCP client for Ollama and OpenAI-compatible LLMs, written in Go, preferring the standard
library. Status: planning, no code yet. The design and phases are in `docs/GO_PORT_PLAN.md`.

## Context Files

Read these before working in this repository:

- `context/project-overview.md` — purpose, planned capabilities and architecture, technology, and
  what the repository doesn't establish yet.
- `context/coding-standards.md` — Go conventions and the plan's design decisions (standard library
  by default, `internal/` layout, interfaces).
- `context/ai-interaction.md` — workflow, permission rules, validation commands, remote and review
  process, commit message and pull request format, and where review output goes.
- `context/testing-instructions.md` — when to write tests, what to test, and the test commands.
- `context/current-feature.md` — the feature being worked on, and the last one completed.

Feature and fix specs are in `context/features/` and `context/fixes/`. The `feature` skill
(`.kiro/skills/feature/`, also linked from `.claude/skills/`) manages them.
