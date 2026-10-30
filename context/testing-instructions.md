# Testing Instructions

No tests exist yet; there is no Go code. This file records the plan from `docs/plans/GO_PORT_PLAN.md`.
Update it with the real commands and layout once Phase 0 lands.

## Framework and Layout

- Standard library `testing` package. No assertion library; adding one needs the user's agreement
  (standard library by default).
- Tests sit next to the code as `*_test.go` files in the same package.
- Use `net/http/httptest` for provider clients (Ollama NDJSON streaming, OpenAI-compatible SSE),
  as the plan's Phase 1 check describes.
- Use `t.TempDir()` and `t.Setenv("HOME", ...)` for anything that reads or writes config. Never
  touch config in the real home directory.

## When Tests Are Warranted

Each phase in the plan ends with ported tests, and names the Python suites to port (for example
`test_server_discovery.py` in Phase 2, `test_streaming_manager.py` in Phase 8).
Port the cases, not the Python structure.

Test:

- Parsing and framing: NDJSON and SSE chunks, JSON-RPC messages, config and `mcpServers` files.
- Agent loop logic: tool wire names and collision suffixes, loop limit choices, tool response
  extraction.
- Config precedence (`local > project > user`), validation, and `mcpherd import ollmcp` (no source
  setup, fresh import, files already present).
- Concurrency in the MCP client and abort handling; run these with `-race`.

Skip: terminal drawing itself (test the matching and state logic separately, as the Phase 11 plan
says), and thin wrappers around the standard library.

## Commands

Planned; not yet run against real code.

- All tests: `go test ./...`
- One package: `go test ./internal/<package>/...`
- One test: `go test ./internal/<package>/ -run '^TestName$'`
- Race detector: `go test -race ./...`
- Also run `go vet ./...` and `gofmt -l .` before reporting a change as done.

Some checks in the plan need real external systems: a real Python and Node MCP server (Phase 2),
`qwen3:0.6b` on a local Ollama (Phase 1), one real OpenRouter call (Phase 7). Keep those out of
`go test ./...` (for example behind a build tag or an environment variable) so the default suite
runs offline. Report which of them were run.

## Parallel Safety

Unknown until tests exist. Tests that start servers should use `httptest` (random ports), and
tests that touch files should use `t.TempDir()`, so the suite can run in several worktrees at once.
