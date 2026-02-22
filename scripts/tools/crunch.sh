#!/bin/bash
# Tool: crunch
# Skill: skills/crunch/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Geração de wordlists customizadas por padrão, charset e comprimento
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"crunch\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== crunch ==="

echo "-- dry-run --"
dry "4-6 alphanumeric"    "4 6 abcdefghijklmnopqrstuvwxyz0123456789"
dry "8 char digits only"  "8 8 0123456789"
dry "fixed pattern"       "8 8 -t @@@@%%%%"
dry "with output file"    "6 8 abcdef -o /tmp/crunch_wordlist.txt"
dry "lowercase + digits"  "4 4 abc123 -o /tmp/crunch_short.txt"
dry "custom charset"      "8 8 -f /usr/share/crunch/charset.lst mixalpha-numeric"
dry "start from word"     "5 5 abc123 -s abc12"
dry "uppercase pattern"   "8 8 -t %%%%@@@@"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
