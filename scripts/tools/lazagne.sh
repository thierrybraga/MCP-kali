#!/bin/bash
# Tool: lazagne
# Skill: skills/lazagne/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Extração de credenciais armazenadas em browsers, SO e aplicações
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
    -d "{\"tool\":\"lazagne\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== lazagne ==="

echo "-- dry-run --"
dry "all modules"        "all"
dry "browsers only"      "browsers"
dry "memory modules"     "memory"
dry "databases"          "databases"
dry "mails"              "mails"
dry "wifi passwords"     "wifi"
dry "verbose"            "all -v"
dry "json output"        "all -oJ /tmp/lazagne_results.json"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
