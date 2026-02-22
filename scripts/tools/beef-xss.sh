#!/bin/bash
# Tool: beef-xss
# Skill: skills/beef-xss/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Browser Exploitation Framework — controle de navegadores via XSS
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
    -d "{\"tool\":\"beef-xss\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== beef-xss ==="

echo "-- dry-run --"
dry "start BeEF"    "--config /etc/beef-xss/config.yaml"
dry "headless mode" "--no-browser --config /etc/beef-xss/config.yaml"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
