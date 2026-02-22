#!/bin/bash
# Tool: davtest
# Skill: skills/davtest/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Teste de permissões WebDAV: upload, execução de scripts e métodos HTTP
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
    -d "{\"tool\":\"davtest\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== davtest ==="

echo "-- dry-run --"
dry "basic test"         "http://$TARGET" "-url http://$TARGET"
dry "with auth"          "http://$TARGET" "-url http://$TARGET -auth admin:password"
dry "cleanup after"      "http://$TARGET" "-url http://$TARGET -cleanup"
dry "rand string"        "http://$TARGET" "-url http://$TARGET -rand testdav"
dry "verbose"            "http://$TARGET" "-url http://$TARGET -debug"
dry "test specific type" "http://$TARGET" "-url http://$TARGET -uploadfile /tmp/test.php -uploadloc /tmp/test.php"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
