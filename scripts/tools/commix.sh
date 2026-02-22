#!/bin/bash
# Tool: commix
# Skill: skills/commix/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Detecção e exploração de vulnerabilidades de injeção de comandos OS
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
    -d "{\"tool\":\"commix\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== commix ==="

echo "-- dry-run --"
dry "GET param inject"   "http://$TARGET" "-u http://$TARGET/ping.php?ip=127.0.0.1 --batch"
dry "POST param inject"  "http://$TARGET" "-u http://$TARGET/api/exec --data 'cmd=test' --batch"
dry "all techniques"     "http://$TARGET" "-u http://$TARGET/ping.php?ip=test --technique=all --batch"
dry "file-based tech"    "http://$TARGET" "-u http://$TARGET/ping.php?ip=test --technique=fb --batch"
dry "time-based tech"    "http://$TARGET" "-u http://$TARGET/ping.php?ip=test --technique=tb --batch"
dry "with cookie"        "http://$TARGET" "-u http://$TARGET/ping.php?ip=test -H 'Cookie: sid=abc' --batch"
dry "os-shell"           "http://$TARGET" "-u http://$TARGET/ping.php?ip=test --os-shell --batch"
dry "with proxy"         "http://$TARGET" "-u http://$TARGET/ping.php?ip=test --proxy http://127.0.0.1:8080 --batch"
dry "skip empty"         "http://$TARGET" "-u http://$TARGET/ping.php?ip=test --skip-empty --batch"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
