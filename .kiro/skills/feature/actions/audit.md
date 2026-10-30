# Audit Action

Check unfinished specs against the code as it is now and against each other, and fix the drift
before someone builds from a stale spec. `complete` step 10 carries a finished feature's *findings*
forward, but it can't see three things this action looks for:

- **Unowned gaps:** something several specs rely on that none of them builds, or a choice written
  as "do X or Y" in more than one spec.
- **Assumed code:** a spec that leans on a function, type, field, command or setting that doesn't
  exist or doesn't behave the way the spec says.
- **Wrong dependencies:** a `depends_on` list that leaves out a spec it uses, and naming that would
  collide (commands, config keys, public names, test file basenames).

Two scopes share the checks below:

- **Full audit** (`audit`, or `audit all`): every unfinished spec. Worth running after `plan`
  creates specs, after a milestone, or when several features have finished since the last one.
- **Single-spec audit** (`audit <nn-name>`, and step 4 of `load`): one spec, with every other spec
  read only for the cross-spec check.

Commands below are `scripts/spec-fields.sh` in this skill's directory, run from the repository
root; see the Spec Files section of `SKILL.md`.

## Steps

1. Read `context/current-feature.md`, `context/ai-interaction.md` and `context/coding-standards.md`.
   Run `check`. List the unfinished specs with `outstanding`. Specs follow `templates/spec.md`;
   field and section names below refer to it.
   `Complete` specs are not audited or edited, except for the format conversion in step 2. If one
   is now wrong, report it and ask whether it should reopen.
2. **Convert old-format specs.** For every spec `check` reports as "no frontmatter", in either
   scope and whatever its status, and with the user's agreement:
   - Build the frontmatter from the old lines: `**Status:**` becomes `status`, and a
     `Complete — merged YYYY-MM-DD (<sha>)` value becomes `status: Complete` plus
     `merged: YYYY-MM-DD (<sha>)`. The `**Depends on:**` line becomes `depends_on` ids: resolve
     numbers and ranges such as "features 91–99" to filenames, and ask when one is ambiguous.
     `none` becomes `[]`. The `## Touches` bullets that are paths become `touches`; move any other
     bullets to `## Notes`.
   - Show the converted frontmatter for each spec and wait for agreement before writing.
   - Write the frontmatter as the first lines of the file, then remove the old `**Status:**` and
     `**Depends on:**` lines and the `## Touches` section, so the values exist only once.
   - Run `check` again. Conversion changes the format, not the content: it is the one edit allowed
     on a `Complete` spec.
3. Read `docs/work-log.md` for the completed features. A full audit reads it all; a single-spec
   audit reads the entries for the spec's dependencies and anything the spec says "comes from".
4. For each spec in scope, check:
   - **Frontmatter.** Everything `check` reports for the spec: malformed lines, missing fields, an
     unknown `status`, a `depends_on` id with no file, a dependency cycle.
   - **Code claims.** Every file, module, function, type, signature, field, command, config key,
     setting and test fixture the spec names, checked against the code, not against memory or
     another spec. Note what is missing or shaped differently.
   - **Inherited work.** Everything the spec says an earlier spec provides was actually built that
     way, according to the code and that spec's work-log entry. An earlier spec that deferred work
     into this one is covered.
   - **Dependencies.** `depends_on` lists every spec whose output this one uses. Read the body for
     references (by number, filename or what they provide) and compare them with the list. Use
     `dependents <id>` to see what relies on this spec.
   - **Open choices.** Anything the spec leaves undecided ("X or Y", "decide whether") that another
     spec also relies on. Settle it in the earliest spec that needs it, then make the later specs
     point to that decision.
   - **Collisions.** Run `overlaps` and note every pair that includes this spec, even when the two
     don't depend on each other. Also compare any new commands, config keys, public names and test
     file basenames the spec introduces with existing code and other unfinished specs.
   - **Touches.** `touches` matches the Goals and the code: add paths the work will clearly change,
     and remove ones it won't. Fill it from the Goals and the code when it is `[]`.
   - **Structure.** The spec has every section in `templates/spec.md`. Add missing sections with
     their placeholder comments.
   - **Project fit.** Goals still match the project's scope (`context/project-overview.md`, plus
     any root agent instructions file such as `AGENTS.md`) and the plan document named under the
     spec's `Context`. Report it if a spec builds something now out of scope, or duplicates
     something already built.
5. Fix in place, in each spec's existing style:
   - Notes, `What <nn> turned up` blocks, Testing guidance, `depends_on`, `touches`, frontmatter
     format problems and missing template sections may be edited without asking. Replace stale
     text rather than adding a contradicting note.
   - A change to Goals, Acceptance Criteria or Non-goals changes what will be built. Propose it,
     get the user's agreement, then make it with `(updated YYYY-MM-DD, audit)`.
   - A cross-cutting decision is written once, in the spec that owns it, and later specs refer to
     it by name. Show the user these decisions before applying them across specs.
   - Never change `status` or `merged`.
   - Run `check` after editing; it should report nothing for the specs in scope.
6. A full audit covers many specs. If the tool supports sub-agents, split the reading across them
   by spec range, and include "When Stuck" from `context/ai-interaction.md` in each brief;
   otherwise work through the specs in order. Either way, settle
   the cross-cutting decisions first, apply the same list everywhere, and review the result for
   consistency before reporting.
7. Report: specs converted; specs changed, with the gist of each edit; decisions made, and which
   spec now owns each; overlaps found; anything left for the user (proposed Goals changes,
   completed specs that look wrong). If nothing needed changing, say so plainly.

This action edits only spec files. It never touches code, commits or branches; the user decides
when the spec changes are committed.
