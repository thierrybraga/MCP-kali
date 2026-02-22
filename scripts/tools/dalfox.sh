#!/bin/bash
# Tool: dalfox
# Skill: skills/dalfox/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Scanner XSS automatizado com fuzzing de parâmetros
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
    -d "{\"tool\":\"dalfox\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== dalfox ==="

echo "-- dry-run --"
dry "URL scan"           "http://$TARGET/search?q=test" "url http://$TARGET/search?q=test"
dry "with headers"       "http://$TARGET"               "url http://$TARGET/search?q=test -H 'Cookie: session=abc'"
dry "blind XSS server"   "http://$TARGET"               "url http://$TARGET/search?q=test -b https://myblind.xss.ht"
dry "pipe from file"     ""                             "file /tmp/urls.txt"
dry "pipe from stdin"    ""                             "pipe"
dry "DOM XSS"            "http://$TARGET"               "url http://$TARGET/#test"
dry "skip mining"        "http://$TARGET"               "url http://$TARGET/search?q=test --skip-mining-dict"
dry "output JSON"        "http://$TARGET"               "url http://$TARGET/search?q=test -o /tmp/dalfox.json --format json"
dry "WAF bypass"         "http://$TARGET"               "url http://$TARGET/search?q=test --waf-bypass"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
