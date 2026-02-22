#!/bin/bash
# Tool: set
# Skill: skills/set/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Social-Engineer Toolkit — phishing, credential harvesting, payloads
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"set\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== set (Social-Engineer Toolkit) ==="

echo "-- dry-run --"
dry "credential harvester"    "--batch --no-gui -c '1;2;3;http://legitimate.com;$TARGET'"
dry "spear phishing"          "--batch --no-gui -c '1;1'"
dry "web attack"              "--batch --no-gui -c '2;1'"
dry "create payload"          "--batch --no-gui -c '1;4;1;$TARGET;4444'"
dry "list attack vectors"     "--batch --no-gui -c '?'"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
