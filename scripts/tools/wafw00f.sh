#!/bin/bash
# Tool: wafw00f
# Skill: skills/wafw00f/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Detecção e fingerprinting de Web Application Firewalls (WAF)
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
    -d "{\"tool\":\"wafw00f\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== wafw00f ==="

echo "-- dry-run --"
dry "basic detection"    "http://$TARGET" "http://$TARGET"
dry "all WAFs check"     "http://$TARGET" "http://$TARGET -a"
dry "verbose"            "http://$TARGET" "http://$TARGET -v"
dry "list WAFs"          ""               "-l"
dry "JSON output"        "http://$TARGET" "http://$TARGET -o /tmp/wafw00f_$TARGET.json -f json"
dry "CSV output"         "http://$TARGET" "http://$TARGET -o /tmp/wafw00f_$TARGET.csv -f csv"
dry "HTTPS"              "https://$TARGET" "https://$TARGET -a"
dry "no redirect"        "http://$TARGET" "http://$TARGET --no-redirect"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
