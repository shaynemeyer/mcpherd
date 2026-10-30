# Explain Action

1. Read `context/current-feature.md` and the spec on its `**Spec:**` line to understand what was
   implemented.
2. Run `git diff <base>...HEAD --name-only` to get the list of files changed, where `<base>` is the
   base branch named in `context/ai-interaction.md` (ask if it isn't recorded). Add
   `git status --porcelain` for changes not yet committed.
3. For each file created or modified:
   - Show the file path
   - Give a 1-2 sentence explanation of what it does / what changed
   - Highlight any key functions, types, or patterns used
4. End with a brief summary of how the pieces fit together.
5. Offer to reuse the explanation: as the summary in the review request copy that `complete`
   proposes, or as the starting point for the feature's `docs/work-log.md` entry. Don't write
   either file from this action.

## Output Format

### Files Changed

**path/to/new_file** (new)
Brief explanation of what this file does and why it was added.

**path/to/existing_file** (modified)
What changed and why.

### How It All Connects

Brief summary of the data/control flow between these files.
