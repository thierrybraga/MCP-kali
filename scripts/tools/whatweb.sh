#!/bin/bash
# Tool: whatweb
# Skill: skills/whatweb/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Fingerprinting de tecnologias web (CMS, framework, servidor, linguagem)
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
    -d "{\"tool\":\"whatweb\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== whatweb ==="

echo "-- dry-run --"
dry "basic scan"         "http://$TARGET" "http://$TARGET"
dry "aggressive mode"    "http://$TARGET" "http://$TARGET -a 3"
dry "verbose"            "http://$TARGET" "http://$TARGET -v"
dry "JSON output"        "http://$TARGET" "http://$TARGET --log-json=/tmp/whatweb_$TARGET.json"
dry "multi target"       "192.168.1.0/24" "192.168.1.0/24 -a 1"
dry "HTTPS"              "https://$TARGET" "https://$TARGET"
dry "with cookies"       "http://$TARGET" "http://$TARGET -H 'Cookie: session=abc'"
dry "grep plugins"       "http://$TARGET" "http://$TARGET --grep WordPress"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
