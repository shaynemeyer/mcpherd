# Load Action

1. Interpret what the user supplied after "load":
   - Looks like a filename (single word, no spaces): look for `context/features/{name}.md` OR
     `context/fixes/{name}.md`.
   - Multiple words: treat it as an inline feature description. Write a spec for it from
     `templates/spec.md`: number it after the highest prefix in `context/features/` and
     `context/fixes/`, put it in `context/fixes/` if it describes a bug fix and `context/features/`
     otherwise, fill Context with "provided inline" and the description, and draft Goals,
     Acceptance Criteria, Non-goals and Touches from it. Show the draft and get the user's agreement
     before continuing. From here on it is an ordinary spec file.
   - Nothing supplied: stop and report that `load` requires a spec filename or feature description.

2. Check the spec's own `**Status:**` line:
   - `Complete`: say so and confirm before proceeding. Loading a finished feature is usually a
     mistake.
   - `In Progress`: this feature was started earlier and never completed. Say so, and check for a
     leftover branch before continuing.

3. Clear stale `In Progress` markers, using the in-progress pattern from `SKILL.md`. Every hit other
   than the spec being loaded is stale. Set each back to `Not Started`, and say which ones were reset
   — an abandoned attempt may also have left a branch and uncommitted work behind that the user has
   forgotten about.

4. Audit the spec before loading it. Skip this for a spec written in step 1 from an inline
   description, since it was just checked with the user. Run the single-spec audit in
   `actions/audit.md`, steps 1–4, scoped to this spec: check every code claim against the code, its
   `Depends on:` line, what it inherits from earlier specs, open choices it shares with other specs,
   and collisions. Fix notes and dependency lines in place. Changes to Goals need the user's
   agreement first. Report what the audit changed, or that the spec was current. If the audit turns
   up a gap that other unfinished specs share, suggest a full `audit`.

5. Update `context/current-feature.md`:
   - Update the H1 heading to include the feature name (e.g. `# Current Feature: Add Navbar`).
   - Set the `**Spec:**` line to the spec's path (e.g. `**Spec:** context/features/04-add-navbar.md`).
   - Write the spec's Goals as bullet points under `## Goals`, followed by its Acceptance Criteria.
   - Write its Notes and Non-goals under `## Notes`.
   - Set Status to "Not Started".

   Leave the spec's own `**Status:**` line alone. `start` is what marks the work underway, so
   loading a spec in order to read it must not claim someone is working on it.

6. Confirm the spec loaded and show the feature summary.
