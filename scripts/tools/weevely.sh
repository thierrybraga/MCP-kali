#!/bin/bash
# Tool: weevely
# Skill: skills/weevely/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Web shell PHP stealth para pós-exploração de aplicações web
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
    -d "{\"tool\":\"weevely\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== weevely ==="

echo "-- dry-run --"
dry "generate shell"     "generate MySecretPass /tmp/weevely_shell.php"
dry "connect shell"      "http://$TARGET/shell.php MySecretPass"
dry "run command"        "http://$TARGET/shell.php MySecretPass 'id; whoami'"
dry "file manager cmd"   "http://$TARGET/shell.php MySecretPass ':file.ls /'"
dry "network cmd"        "http://$TARGET/shell.php MySecretPass ':net.ifaces'"
dry "audit cmd"          "http://$TARGET/shell.php MySecretPass ':audit.etcpasswd'"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
