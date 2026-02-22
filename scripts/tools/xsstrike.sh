#!/bin/bash
# Tool: xsstrike
# Skill: skills/xsstrike/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Detecção avançada de XSS com análise DOM e fuzzing inteligente
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"xsstrike\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== xsstrike ==="

echo "-- dry-run --"
dry "basic scan"         "http://$TARGET" "-u http://$TARGET/search?q=test"
dry "crawl mode"         "http://$TARGET" "-u http://$TARGET --crawl"
dry "DOM analysis"       "http://$TARGET" "-u http://$TARGET/search?q=test --dom"
dry "blind XSS"          "http://$TARGET" "-u http://$TARGET/search?q=test --blind"
dry "JSON data"          "http://$TARGET" "-u http://$TARGET/api/search -d '{\"q\":\"test\"}' --json"
dry "custom headers"     "http://$TARGET" "-u http://$TARGET/search?q=test -H 'Cookie: sid=abc'"
dry "skip DOM"           "http://$TARGET" "-u http://$TARGET/search?q=test --skip"
dry "with proxy"         "http://$TARGET" "-u http://$TARGET/search?q=test --proxy http://127.0.0.1:8080"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
