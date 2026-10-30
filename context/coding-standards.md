# Coding Standards

The codebase is empty, so there are no established conventions to derive. This file records what
`docs/GO_PORT_PLAN.md` decides and standard Go practice for the stack it names. Replace the general
items with the project's actual patterns as code lands.

## From the Plan

- Standard library by default. External modules only where hand-rolling costs more than it gains,
  and only with the user's agreement. Expected: `golang.org/x/term`, maybe the MCP go-sdk.
- Layout: `cmd/mcpherd` for the binary, everything else under `internal/` (see
  `context/project-overview.md` for the package list).
- CLI with the standard `flag` package, one `FlagSet` per subcommand.
- Terminal output with ANSI escape codes and `text/tabwriter`; no TUI framework.
- `internal/llm` providers behind the `Provider` interface, MCP transports behind the `Transport`
  interface, both in `docs/GO_PORT_PLAN.md` "Key interfaces".
- Split by responsibility into packages rather than porting large classes line by line.
- Cancellation through `context.Context` (abort uses `context.WithCancel`).
- MCP stdio server stderr goes to the log file, never to the screen.
- Write config only inside `~/.config/mcpherd/`. Never write to another tool's config directory;
  the import command only reads from its source.

## Go Conventions

Not yet observed in this repository; standard practice until the code shows otherwise.

- Format with `gofmt`. Check with `go vet`.
- Names: `MixedCaps`, short package names without underscores, no stutter (`llm.Provider`, not
  `llm.LLMProvider`).
- Errors: return `error` values, wrap with `fmt.Errorf("...: %w", err)`, and compare with
  `errors.Is` / `errors.As`. No `panic` for ordinary failures.
- Pass `context.Context` as the first parameter of anything that does I/O or can block.
- Validate input at trust boundaries: config files, MCP server responses, and model tool calls are
  all untrusted.
- Goroutines must have a clear owner and a way to stop; run concurrent code's tests with `-race`.

## Linting and Formatting

Configured: nothing yet. Planned for CI: `go vet` (Phase 0). No `golangci-lint` or `staticcheck`
configuration exists; adding one is a decision for the user.
