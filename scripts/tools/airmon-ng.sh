#!/bin/bash
# Tool: airmon-ng
# Skill: skills/airmon-ng/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Gerenciamento de modo monitor em interfaces wireless
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
    -d "{\"tool\":\"airmon-ng\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== airmon-ng ==="

echo "-- dry-run --"
dry "list interfaces"   ""
dry "check processes"   "check"
dry "kill processes"    "check kill"
dry "start monitor"     "start wlan0"
dry "start on channel"  "start wlan0 6"
dry "stop monitor"      "stop wlan0mon"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
