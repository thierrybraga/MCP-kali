#!/bin/bash
# Tool: ophcrack
# Skill: skills/ophcrack/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Crack de hashes LM/NTLM Windows via rainbow tables
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"ophcrack\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== ophcrack ==="

echo "-- dry-run --"
dry "crack NTLM hash"     "/tmp/ntlm.txt"    "-t /usr/share/ophcrack/tables/vista_free -f /tmp/ntlm.txt -c"
dry "crack LM hash"       "/tmp/lm.txt"      "-t /usr/share/ophcrack/tables/xp_free_fast -f /tmp/lm.txt -c"
dry "from SAM+SYSTEM"     "/tmp"             "-t /usr/share/ophcrack/tables/vista_free -d /tmp/SAM -s /tmp/SYSTEM -c"
dry "export results"      "/tmp/ntlm.txt"    "-t /usr/share/ophcrack/tables/vista_free -f /tmp/ntlm.txt -c -e /tmp/ophcrack_results.csv"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
