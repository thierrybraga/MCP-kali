#!/bin/bash
# Tool: unicornscan
# Skill: skills/unicornscan/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Scanner de portas assíncrono com análise estatística
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
    -d "{\"tool\":\"unicornscan\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== unicornscan ==="

echo "-- dry-run --"
dry "TCP scan rate 100"     "$TARGET"        "-mT -Iv $TARGET:a -r 100"
dry "UDP scan"              "$TARGET"        "-mU -Iv $TARGET:a -r 50"
dry "specific ports"        "$TARGET"        "-mT -Iv $TARGET:80,443,22,21 -r 200"
dry "CIDR range"            "192.168.1.0/24" "-mT -Iv 192.168.1.0/24:a -r 500"
dry "SYN scan verbose"      "$TARGET"        "-mT -Iv $TARGET:1-1024 -r 100 -v"
dry "save output"           "$TARGET"        "-mT -Iv $TARGET:a -r 100 -l /tmp/unicorn.log"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
