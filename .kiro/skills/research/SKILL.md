---
name: research
description: Run a research task to generate documentation, given a prompt-name argument
---

## Task

Execute the research task named by the given prompt-name argument.

---

### Instructions

1. If no prompt-name is given, list the prompts available in `context/research/` and reply with
   "Usage: research <prompt-name>".
2. Look for the prompt file at `context/research/{prompt-name}.md`.
3. If it's not found, reply with "Prompt file not found at context/research/{prompt-name}.md" and
   list the prompts that do exist.
4. Read the prompt file. It should contain:
   - **Output**: where to write the results (e.g. `docs/content-types.md`)
   - **Research**: what to investigate
   - **Include**: specific details to capture
   - **Sources**: which files and tools to use
5. Read the project context (`context/project-overview.md`, or the root `AGENTS.md`) to learn the
   stack and where things live. Then do the research with the tools that fit:
   - Read source files, such as models and schemas, configuration, constants, routes, templates,
     and components
   - Search the codebase for patterns
   - Use MCP tools or other configured integrations, such as Confluence, Jira, or a database, only
     when the prompt's Sources call for them, and only read-only
6. Write the findings to the specified output location.
7. Summarize what you found, and state anything you could not verify.

---

### Rules

- This task produces DOCUMENTATION only
- Do NOT modify source code files
- Do NOT create branches or commits
- Output goes to `docs/` unless the prompt specifies otherwise
- Use mock or sanitized examples. Don't copy secrets or personal data from sources into the output
- Use subagents for thorough exploration if needed
