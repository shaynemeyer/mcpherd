#!/bin/sh
# spec-fields.sh: read the YAML frontmatter of feature-skill spec files.
#
# Usage: sh <skill-dir>/scripts/spec-fields.sh [command] [args]
# Run it from the repository root. Spec folders default to "context/features context/fixes";
# set SPEC_DIRS to a space-separated list to override.
#
# Commands:
#   fields            every value: <spec-id> TAB <field> TAB <value> (lists: one row per item)
#   status            <spec-id> TAB <status>
#   outstanding       ids whose status is not Complete
#   complete          ids whose status is Complete
#   in-progress       ids whose status is In Progress
#   next              lowest-numbered outstanding id whose depends_on are all Complete
#   dependents ID     ids whose depends_on includes ID
#   order             all ids in dependency order (exit 1 on a cycle)
#   overlaps [ID...]  pairs of specs whose touches overlap: <path> TAB <id> TAB <id>
#                     (a folder ending in "/" overlaps every path inside it). With IDs, only
#                     pairs among those specs.
#   check             every problem with the specs; exit 1 if there are any
#
# Spec ids are filenames without ".md". Frontmatter rules: the first line is "---" and the block
# ends at the next "---"; one "key: value" per line; lists are the key alone, then "  - item"
# lines, or "key: []" when empty. No quotes, comments, flow lists with items, or nesting.

set -u
cmd=${1:-fields}
[ $# -gt 0 ] && shift
dirs=${SPEC_DIRS:-context/features context/fixes}

# rows: raw rows for every spec. Besides field rows, "_key" rows record each key present, and
# "_error" rows record parse problems.
rows() {
  # shellcheck disable=SC2086
  find $dirs -type f -name '*.md' 2>/dev/null | sort | while IFS= read -r f; do
    awk -v file="$f" '
      BEGIN { n = split(file, p, "/"); id = p[n]; sub(/\.md$/, "", id); state = 0; key = "" }
      function err(msg) { print id "\t_error\t" msg }
      # Windows checkouts can have CRLF line endings; drop the carriage return first.
      { sub(/\r$/, "") }
      NR == 1 {
        if ($0 == "---") { state = 1 }
        else { state = 3; err("no frontmatter (old format? run audit to convert)") }
        next
      }
      state == 1 && $0 == "---" { state = 2; next }
      state == 1 && /^[a-z_]+:/ {
        key = $0; sub(/:.*/, "", key)
        val = $0; sub(/^[a-z_]+:[ ]*/, "", val)
        print id "\t_key\t" key
        if (val == "[]") next
        if (val ~ /^\[/) { err("line " NR ": list must use \"  - item\" lines, not [...]"); next }
        if (val ~ /^["\047]/) { err("line " NR ": value must not be quoted"); next }
        if (val ~ / #/) { err("line " NR ": no comments in frontmatter"); next }
        if (val != "") print id "\t" key "\t" val
        next
      }
      state == 1 && /^  - / {
        if (key == "") { err("line " NR ": list item before any key"); next }
        val = $0; sub(/^  - /, "", val); print id "\t" key "\t" val; next
      }
      state == 1 && /^[ ]*$/ { next }
      state == 1 { err("line " NR ": not a \"key: value\" or \"  - item\" line"); next }
      state == 2 && (/^\*\*Status:\*\*/ || /^\*\*Depends on:\*\*/ || /^## Touches[ ]*$/) {
        err("line " NR ": old-format line in body: " $0); next
      }
      END { if (state == 1) err("frontmatter is not closed with ---") }
    ' "$f"
  done
}

fields() { rows | awk -F'\t' '$2 != "_key"'; }

case $cmd in
  fields)
    fields
    ;;
  status)
    fields | awk -F'\t' '$2 == "status" { print $1 "\t" $3 }'
    ;;
  outstanding)
    fields | awk -F'\t' '$2 == "status" && $3 != "Complete" { print $1 }'
    ;;
  complete)
    fields | awk -F'\t' '$2 == "status" && $3 == "Complete" { print $1 }'
    ;;
  in-progress)
    fields | awk -F'\t' '$2 == "status" && $3 == "In Progress" { print $1 }'
    ;;
  next)
    fields | awk -F'\t' '
      $2 == "status" { st[$1] = $3 }
      $2 == "depends_on" { dep[$1] = dep[$1] " " $3 }
      END {
        for (s in st) {
          if (st[s] == "Complete") continue
          ok = 1; m = split(dep[s], d, " ")
          for (i = 1; i <= m; i++) if (st[d[i]] != "Complete") ok = 0
          if (ok) print s
        }
      }' | sort | head -n 1
    ;;
  dependents)
    [ $# -eq 1 ] || { echo "usage: spec-fields.sh dependents ID" >&2; exit 2; }
    fields | awk -F'\t' -v want="$1" '$2 == "depends_on" && $3 == want { print $1 }' | sort
    ;;
  order)
    # Kahn's algorithm in awk: no dependence on tsort, which BusyBox lacks and macOS reports
    # cycles from with exit code 0. Ties go to the lowest id, so the order is stable.
    fields | awk -F'\t' '
      $2 == "status" { ids[$1] = 1; if (!($1 in indeg)) indeg[$1] = 0 }
      $2 == "depends_on" && $3 != "" { e++; from[e] = $3; to[e] = $1; indeg[$1]++ }
      END {
        for (i = 1; i <= e; i++) if (!(from[i] in ids)) indeg[to[i]]--
        left = 0; for (s in ids) left++
        while (left > 0) {
          pick = ""
          for (s in ids) if (!(s in done) && indeg[s] == 0 && (pick == "" || s < pick)) pick = s
          if (pick == "") break
          print pick; done[pick] = 1; left--
          for (i = 1; i <= e; i++) if (from[i] == pick) indeg[to[i]]--
        }
        if (left > 0) {
          msg = "dependency cycle:"
          for (s in ids) if (!(s in done)) msg = msg " " s
          print msg > "/dev/stderr"; exit 1
        }
      }'
    ;;
  overlaps)
    fields | awk -F'\t' -v only="$*" '
      BEGIN { n = split(only, o, " "); for (i = 1; i <= n; i++) keep[o[i]] = 1 }
      $2 == "touches" && (n == 0 || ($1 in keep)) { c++; spec[c] = $1; path[c] = $3 }
      function inside(a, b) { return substr(a, length(a)) == "/" && index(b, a) == 1 }
      END {
        for (i = 1; i <= c; i++) for (j = i + 1; j <= c; j++) {
          if (spec[i] == spec[j]) continue
          a = path[i]; b = path[j]
          if (a == b || inside(a, b)) hit = b; else if (inside(b, a)) hit = a; else continue
          x = spec[i]; y = spec[j]; if (x > y) { t = x; x = y; y = t }
          line = hit "\t" x "\t" y
          if (!(line in seen)) { seen[line] = 1; print line }
        }
      }' | sort
    ;;
  check)
    problems=$(rows | awk -F'\t' '
      $2 == "_error" { print $1 ": " $3; bad[$1] = 1; next }
      $2 == "_key" { has[$1, $3] = 1; ids[$1] = 1; next }
      { ids[$1] = 1 }
      $2 == "status" { st[$1] = $3 }
      $2 == "merged" { mg[$1] = $3 }
      $2 == "depends_on" { nd++; dfrom[nd] = $1; dto[nd] = $3 }
      END {
        for (s in ids) {
          if (s in bad) continue
          split("status depends_on touches", req, " ")
          for (i = 1; i <= 3; i++) if (!((s, req[i]) in has)) print s ": missing " req[i]
          v = st[s]
          if ((s, "status") in has && v != "Not Started" && v != "In Progress" && v != "Complete")
            print s ": unknown status \"" v "\""
          if (v == "Complete" && !(s in mg)) print s ": Complete but no merged"
          if (s in mg && mg[s] !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] \([0-9a-f]+\)$/)
            print s ": merged must be YYYY-MM-DD (<sha>), got \"" mg[s] "\""
          if (s in mg && v != "Complete") print s ": merged is set but status is not Complete"
        }
        for (i = 1; i <= nd; i++) {
          if (dto[i] == dfrom[i]) print dfrom[i] ": depends on itself"
          else if (!(dto[i] in ids)) print dfrom[i] ": depends on missing spec " dto[i]
        }
      }' | sort)
    dupes=$(find $dirs -type f -name '*.md' 2>/dev/null | awk -F/ '{ print $NF }' | sort | uniq -d)
    for d in $dupes; do problems="$problems
${d%.md}: same filename in more than one spec folder"; done
    cycle=$(SPEC_DIRS="$dirs" sh "$0" order 2>&1 >/dev/null) || problems="$problems
$cycle"
    problems=$(printf '%s\n' "$problems" | sed '/^$/d')
    if [ -n "$problems" ]; then printf '%s\n' "$problems"; exit 1; fi
    ;;
  -h|--help|help)
    sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    echo "unknown command: $cmd (try: help)" >&2; exit 2
    ;;
esac
