#!/bin/bash
# Tool: sublist3r
# Skill: skills/sublist3r/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Enumeração de subdomínios via múltiplos motores de busca
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
DOMAIN="${TEST_DOMAIN:-example.com}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"sublist3r\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== sublist3r ==="

echo "-- dry-run --"
dry "basic enum"        "$DOMAIN" "-d $DOMAIN"
dry "specific engines"  "$DOMAIN" "-d $DOMAIN -e google,bing,yahoo"
dry "with ports"        "$DOMAIN" "-d $DOMAIN -p 80,443,8080"
dry "verbose"           "$DOMAIN" "-d $DOMAIN -v"
dry "output file"       "$DOMAIN" "-d $DOMAIN -o /tmp/sublist3r_$DOMAIN.txt"
dry "brute force"       "$DOMAIN" "-d $DOMAIN -b -t 30"
dry "threads"           "$DOMAIN" "-d $DOMAIN -t 20"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
