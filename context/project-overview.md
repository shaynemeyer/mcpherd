# Project Overview

## Purpose and Problem

mcpherd is a terminal MCP client for Ollama and OpenAI-compatible LLMs, written in Go. It connects a
chat model to MCP servers and lets the model call their tools. It aims for a single static binary
that mostly uses the standard library.

Status: planning. No Go code exists yet. The design is in `docs/GO_PORT_PLAN.md`.

## Users

People who run local models with Ollama, or hosted models through OpenAI-compatible providers such
as OpenRouter, and want those models to use MCP servers from a terminal. The repository does not
establish anything more specific about users.

## Core Capabilities

Implemented: none.

Planned (from `README.md` and `docs/GO_PORT_PLAN.md`, in 13 phases, 0–12):

- Chat with Ollama models and OpenAI-compatible providers, with streaming.
- MCP servers over stdio, streamable HTTP and SSE.
- Agent loop with tool calls, a loop limit, and human-in-the-loop approval; abort during a query.
- MCP prompts, `@resource` injection, chat history, and vision models.
- Slash commands, thinking display, and a minimal markdown renderer.
- `mcpherd mcp add | list | remove` server registry with `local > project > user` precedence.
- `mcpherd import ollmcp`: copies an existing setup's config files, never overwriting.
- A custom line editor with fuzzy completion (last phase before release).

## Architecture and Data

Planned layout (`docs/GO_PORT_PLAN.md`, "Architecture"):

- `cmd/mcpherd`: entry point.
- `internal/cli` (flags, subcommands), `internal/app` (REPL, slash commands), `internal/agent`
  (query loop), `internal/llm` with `llm/ollama` and `llm/openai` behind a `Provider` interface,
  `internal/mcp` (JSON-RPC 2.0 client) with stdio, streamable HTTP and SSE transports behind a
  `Transport` interface, plus `tools`, `hil`, `render`, `term`, `config`, `registry`,
  `discovery`, `history`, `prompts` and `resources`.

Data: JSON config files in `~/.config/mcpherd/` (`config.json`, named configs, `mcp.json`,
`mcp.local.json`, `logs/`). A project's `.mcp.json` stays in the
project root. There is no database.

## Technology and Operations

- Language: Go. Module `github.com/shaynemeyer/mcpherd`, binary `mcpherd` (planned; no `go.mod`
  yet). Go 1.27.3 is installed locally; no minimum Go version is set.
- Dependencies: standard library by default. Expected external modules: `golang.org/x/term`, and
  possibly the official MCP go-sdk (decision at Phase 5).
- Build and test: planned `go build`, `go vet` and `go test ./...` in CI (Phase 0). No CI
  configuration exists yet. See `context/ai-interaction.md` for the commands.
- Distribution: `go install github.com/shaynemeyer/mcpherd/cmd/mcpherd@latest`, and cross-compiled
  release binaries in Phase 12.
- Repository: GitHub, `shaynemeyer/mcpherd`, base branch `main`. MIT license (see `LICENSE`).

## Evidence Gaps

- No code, `go.mod`, tests or CI exist, so every command and package path above is planned, not
  verified.
- Minimum supported Go version and target platforms beyond "Windows CI from Phase 4" are not set.
- Merge style for pull requests is a merge commit. Branch naming,
  commit subjects and treating `main` as protected are recorded in `context/ai-interaction.md`.
- Whether the MCP HTTP/SSE transports are hand-written or use the go-sdk is open until Phase 5.
