#!/bin/sh
# Tests for spec-fields.sh. Usage: sh test-spec-fields.sh   (prints PASS/FAIL, exits 1 on failure)
# Builds sample specs in a temporary folder; touches nothing else.

set -u
here=$(cd "$(dirname "$0")" && pwd)
script="$here/spec-fields.sh"
work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT
fails=0

run() { (cd "$work/$1" && shift && sh "$script" "$@" 2>&1); }

expect() { # expect NAME EXPECTED ACTUAL
  if [ "$2" = "$3" ]; then echo "PASS $1"
  else
    echo "FAIL $1"; echo "  expected:"; printf '%s\n' "$2" | sed 's/^/    /'
    echo "  actual:"; printf '%s\n' "$3" | sed 's/^/    /'; fails=$((fails + 1))
  fi
}

expect_exit() { # expect_exit NAME CODE DIR ARGS...
  name=$1; want=$2; dir=$3; shift 3
  (cd "$work/$dir" && sh "$script" "$@" >/dev/null 2>&1); got=$?
  expect "$name" "exit $want" "exit $got"
}

spec() { # spec DIR FILE  (content on stdin)
  mkdir -p "$work/$(dirname "$1/$2")"; cat > "$work/$1/$2"
}

# --- Scenario "good": a valid set of specs -------------------------------------------------
spec good context/features/01-core-types.md <<'EOF'
---
status: Complete
merged: 2026-11-02 (abc1234)
depends_on: []
touches:
  - internal/llm/
---

# Core types

status: In Progress
EOF
spec good context/features/02-chat-client.md <<'EOF'
---
status: Not Started
depends_on:
  - 01-core-types
touches:
  - internal/llm/ollama/client.go
  - cmd/mcpherd/main.go
---

# Chat client
EOF
spec good context/features/03-slash-commands.md <<'EOF'
---
status: In Progress
depends_on:
  - 01-core-types
touches:
  - internal/app/commands.go
  - cmd/mcpherd/main.go
---

# Slash commands
EOF
spec good context/features/04-agent-loop.md <<'EOF'
---
status: Not Started
depends_on:
  - 02-chat-client
  - 03-slash-commands
touches: []
---

# Agent loop
EOF
spec good context/fixes/05-stdio-hang.md <<'EOF'
---
status: Not Started
depends_on:
  - 01-core-types
touches:
  - internal/mcp/stdio.go
---

# Stdio hang
EOF

expect "fields: body status line ignored, lists one row per item" \
"$(printf '01-core-types\tstatus\tComplete\n01-core-types\tmerged\t2026-11-02 (abc1234)\n01-core-types\ttouches\tinternal/llm/')" \
"$(run good fields | grep '^01-core-types')"
expect "status" \
"$(printf '01-core-types\tComplete\n02-chat-client\tNot Started\n03-slash-commands\tIn Progress\n04-agent-loop\tNot Started\n05-stdio-hang\tNot Started')" \
"$(run good status)"
expect "outstanding includes fixes" \
"$(printf '02-chat-client\n03-slash-commands\n04-agent-loop\n05-stdio-hang')" "$(run good outstanding)"
expect "complete" "01-core-types" "$(run good complete)"
expect "in-progress" "03-slash-commands" "$(run good in-progress)"
expect "next: lowest outstanding with complete deps" "02-chat-client" "$(run good next)"
expect "dependents" "$(printf '02-chat-client\n03-slash-commands\n05-stdio-hang')" \
"$(run good dependents 01-core-types)"
expect "dependents of a leaf" "" "$(run good dependents 04-agent-loop)"
expect "order: dependencies first, ties by lowest id" \
"$(printf '01-core-types\n02-chat-client\n03-slash-commands\n04-agent-loop\n05-stdio-hang')" \
"$(run good order)"
expect "order: dependencies first" "01-core-types" "$(run good order | head -n 1)"
expect "order: every spec listed once" "5" "$(run good order | sort -u | wc -l | tr -d ' ')"
expect "overlaps: same file and folder containment" \
"$(printf 'cmd/mcpherd/main.go\t02-chat-client\t03-slash-commands\ninternal/llm/ollama/client.go\t01-core-types\t02-chat-client')" \
"$(run good overlaps)"
expect "overlaps limited to given ids" "" "$(run good overlaps 03-slash-commands 05-stdio-hang)"
expect "check: valid specs report nothing" "" "$(run good check)"
expect_exit "check: valid specs exit 0" 0 good check

# --- Scenario "empty": no specs, fixes folder missing --------------------------------------
mkdir -p "$work/empty/context/features"
expect "empty: status prints nothing" "" "$(run empty status)"
expect "empty: next prints nothing" "" "$(run empty next)"
expect "empty: order prints nothing" "" "$(run empty order)"
expect_exit "empty: check exits 0" 0 empty check

# --- Scenario "bad": every kind of problem -------------------------------------------------
spec bad context/features/01-old.md <<'EOF'
# Old format

**Status:** Not Started
**Depends on:** none
EOF
spec bad context/features/02-flow-list.md <<'EOF'
---
status: Not Started
depends_on: [01-old, 03-x]
touches: []
---
EOF
spec bad context/features/03-missing-keys.md <<'EOF'
---
status: Done
---
EOF
spec bad context/features/04-complete-no-merged.md <<'EOF'
---
status: Complete
depends_on:
  - 99-nowhere
  - 04-complete-no-merged
touches: []
---
EOF
spec bad context/features/05-bad-merged.md <<'EOF'
---
status: Not Started
merged: yesterday
depends_on: []
touches: []
---
EOF
spec bad context/features/06-unclosed.md <<'EOF'
---
status: Not Started
depends_on: []
EOF
spec bad context/features/07-both-formats.md <<'EOF'
---
status: "Not Started"
depends_on: []
touches: []
---

# Both formats

**Status:** Not Started
EOF
spec bad context/fixes/02-flow-list.md <<'EOF'
---
status: Not Started
depends_on: []
touches: []
---
EOF

bad=$(run bad check)
for want in \
  "01-old: no frontmatter (old format? run audit to convert)" \
  "02-flow-list: line 3: list must use \"  - item\" lines, not [...]" \
  "02-flow-list: same filename in more than one spec folder" \
  "03-missing-keys: missing depends_on" \
  "03-missing-keys: missing touches" \
  "03-missing-keys: unknown status \"Done\"" \
  "04-complete-no-merged: Complete but no merged" \
  "04-complete-no-merged: depends on missing spec 99-nowhere" \
  "04-complete-no-merged: depends on itself" \
  "05-bad-merged: merged must be YYYY-MM-DD (<sha>), got \"yesterday\"" \
  "05-bad-merged: merged is set but status is not Complete" \
  "06-unclosed: frontmatter is not closed with ---" \
  "07-both-formats: line 2: value must not be quoted" \
  "07-both-formats: line 9: old-format line in body: **Status:** Not Started"
do
  if printf '%s\n' "$bad" | grep -qF -- "$want"; then echo "PASS check reports: $want"
  else echo "FAIL check reports: $want"; fails=$((fails + 1)); fi
done
expect_exit "check: problems exit 1" 1 bad check

# --- Scenario "cycle" ----------------------------------------------------------------------
spec cycle context/features/01-a.md <<'EOF'
---
status: Not Started
depends_on:
  - 02-b
touches: []
---
EOF
spec cycle context/features/02-b.md <<'EOF'
---
status: Not Started
depends_on:
  - 01-a
touches: []
---
EOF
expect_exit "order: cycle exits 1" 1 cycle order
expect "check: reports the cycle" "dependency cycle: 01-a 02-b" \
"$(run cycle check | sed 's/02-b 01-a/01-a 02-b/')"
expect "next: nothing is ready in a cycle" "" "$(run cycle next)"

# --- Scenario "crlf": specs saved with Windows line endings -------------------------------
mkdir -p "$work/crlf/context/features"
printf -- '---\r\nstatus: Complete\r\nmerged: 2026-11-02 (abc1234)\r\ndepends_on: []\r\ntouches:\r\n  - internal/llm/\r\n---\r\n\r\n# Core\r\n' \
  > "$work/crlf/context/features/01-core.md"
printf -- '---\r\nstatus: Not Started\r\ndepends_on:\r\n  - 01-core\r\ntouches:\r\n  - internal/llm/ollama/client.go\r\n---\r\n\r\n# Chat\r\n' \
  > "$work/crlf/context/features/02-chat.md"
expect "crlf: status values have no carriage return" \
"$(printf '01-core\tComplete\n02-chat\tNot Started')" "$(run crlf status)"
expect "crlf: next" "02-chat" "$(run crlf next)"
expect "crlf: overlaps" "$(printf 'internal/llm/ollama/client.go\t01-core\t02-chat')" "$(run crlf overlaps)"
expect "crlf: check reports nothing" "" "$(run crlf check)"
expect_exit "crlf: check exits 0" 0 crlf check

# --- SPEC_DIRS override ---------------------------------------------------------------------
expect "SPEC_DIRS limits the folders" "05-stdio-hang" \
"$(cd "$work/good" && SPEC_DIRS=context/fixes sh "$script" outstanding)"

echo
if [ "$fails" -eq 0 ]; then echo "All tests passed."; else echo "$fails test(s) failed."; exit 1; fi
