# mcpherd

A terminal MCP client for Ollama and OpenAI-compatible LLMs, written in Go. It herds MCP servers.

> **Status:** planning. Nothing is built yet. See [docs/GO_PORT_PLAN.md](docs/GO_PORT_PLAN.md).

## Planned features

- Chat with Ollama models, or OpenAI-compatible providers such as OpenRouter.
- Connect to MCP servers over stdio, streamable HTTP and SSE.
- Agent loop with tool calls, a loop limit and human-in-the-loop approval.
- MCP prompts, `@resource` injection, chat history and vision models.
- Slash commands, thinking display and markdown rendering.
- A single static binary that uses the standard library, plus `golang.org/x/term`.

## Planned usage

```sh
go install github.com/shaynemeyer/mcpherd/cmd/mcpherd@latest

mcpherd --model qwen3:0.6b
mcpherd --servers-json servers.json
mcpherd mcp add | list | remove
mcpherd import ollmcp
```

## Configuration

mcpherd keeps its files in `~/.config/mcpherd/`, in the same JSON formats as ollmcp. To bring over an existing ollmcp setup, run `mcpherd import ollmcp`. It copies the files and never overwrites any that already exist. mcpherd never writes to ollmcp's files. A project's `.mcp.json` file stays in the project root.

## Credits

Inspired by [ollmcp](https://github.com/jonigl/mcp-client-for-ollama) by Jonathan Löwenstern; mcpherd is a Go reimplementation of its design.

## License

MIT. See [LICENSE](LICENSE), which also carries ollmcp's MIT notice.
