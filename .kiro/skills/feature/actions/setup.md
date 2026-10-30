# Setup Action

Initialize the target project without overwriting existing context silently. Paths starting
`templates/` are in this skill's directory, wherever the skill is installed.

**Guard — run this check before anything else.** Look at `context/ai-interaction.md`:

- **Absent, empty (whitespace-only), or containing the line `<!-- feature-skill: untailored -->`**
  — not yet set up; setup may continue. A file that still has the marker means an earlier `setup`
  copied the template and stopped before step 2's tailoring finished.
- **Has content and no marker** — the project is already set up. Stop immediately, create and
  change nothing (not even directories), and report that `setup` was skipped because
  `context/ai-interaction.md` is already tailored. Do not offer to proceed anyway or merge into it;
  to re-run setup, the user must empty or remove that file themselves first.
- **`templates/ai-interaction.md` missing, or missing its marker line** — stop and report it; the
  skill is damaged, so do not guess.

1. Create `context/features/`, `context/fixes/`, and `context/research/` if absent.
2. Copy `templates/ai-interaction.md` to `context/ai-interaction.md`, then replace its generic
   wording with repository evidence as the template's own instructions describe. Remove the
   `feature-skill: untailored` marker as the last part of tailoring: its absence is what the guard
   above treats as "set up".
3. Use `templates/project-overview.md` as the structure for `context/project-overview.md`, but inspect the repository and replace prompts with evidenced project facts. State when evidence is absent.
4. Copy `templates/README.md` to `context/README.md`.
5. Copy `templates/current-feature.md` to `context/current-feature.md`.
6. Create `context/testing-instructions.md` from the actual test configuration and conventions: when tests are warranted, what to test, and exact validated commands. Do not assume a framework.
   End it with a `## Parallel Safety` section saying whether the test suite (and the build and
   lint commands) can run in several git worktrees at once, and why: fixed ports, a shared
   database or service, shared temp files or caches outside the worktree. Write "safe", "not
   safe" or "unknown" first, then the evidence. The `parallel` action reads it, and refuses to
   run a batch when it says "not safe".
7. Create `context/coding-standards.md` from repository evidence: language and naming conventions, framework patterns, organization, error handling, validation, configured linting/formatting, and subproject differences. Do not invent conventions for a thin codebase.
8. Make sure review output stays out of source control. Use the review output folder recorded in
   `context/ai-interaction.md` under "Review Output" (`.reviews/` unless the project already uses
   another git-ignored folder). If `git check-ignore -q <folder>/x` reports it isn't ignored, add
   the folder to the root `.gitignore` under a `# Review output` comment, creating `.gitignore` if
   it doesn't exist. Don't create the folder itself. If files under that folder are already
   tracked by git, report them and leave them alone; removing them from git is the user's call.
   Do the same for `.worktrees/`, where the `parallel` action puts its git worktrees: if
   `git check-ignore -q .worktrees/x` reports it isn't ignored, add `.worktrees/` under a
   `# Parallel worktrees` comment.
9. Make the five context files always-on context, using whatever mechanism the project's agent
   tools load automatically. Prefer one shared file over a copy per tool, since a second always-on
   copy is the kind that drifts. For Kiro and Claude Code:

   - **A root `AGENTS.md` exists:** add or update a `## Context Files` section in `AGENTS.md` that
     lists the five files below as plain paths, one bullet each with a short description of its
     contents. Do not create `.kiro/steering/project-context.md`: Kiro loads `AGENTS.md` directly,
     so a steering file would be a second always-on copy. Do not use `@path` imports or
     `#[[file:]]` references inside `AGENTS.md`: Claude Code expands `@path` and Kiro does not, and
     `#[[file:]]` is a steering feature, so either would be read differently by the two tools.
   - **Make sure Claude Code reads `AGENTS.md`.** Claude Code loads `CLAUDE.md`, not `AGENTS.md`.
     - No `CLAUDE.md`: create one containing the single line `@AGENTS.md`.
     - `CLAUDE.md` is a symlink to `AGENTS.md`, or already contains an `@AGENTS.md` line: leave it.
     - `CLAUDE.md` has its own content and no `@AGENTS.md` line: ask before adding `@AGENTS.md` at
       its top, and report any instructions in it that repeat or contradict `AGENTS.md`.
   - **No root `AGENTS.md`**: create or update `.kiro/steering/project-context.md` as shown below.
     Claude Code does not read steering files, so also create a root `CLAUDE.md` containing the
     five `@context/...` paths, one per line, or add them to an existing `CLAUDE.md` after asking.
   - **Either way**, if `.kiro/steering/` already holds always-included prose that repeats what
     the context files say, report it rather than adding to it. Leave it unchanged.
   - **Other tools**: use their equivalent (a root instructions file they read, or their own
     include mechanism), and say in the report which one was used.

   The steering file, for projects without `AGENTS.md`:

```markdown
---
inclusion: always
---

# Project Context

#[[file:context/project-overview.md]]
#[[file:context/coding-standards.md]]
#[[file:context/ai-interaction.md]]
#[[file:context/testing-instructions.md]]
#[[file:context/current-feature.md]]
```

10. Preserve user content in existing files. Show proposed merges or ask before replacing conflicting content.
11. Confirm the exact directories and files created, updated, skipped, or preserved, including any
    `.gitignore` change from step 8.
