#!/bin/bash
# Tool: paramspider
# Skill: skills/paramspider/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Extração de parâmetros URL de URLs arquivadas para fuzzing
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
    -d "{\"tool\":\"paramspider\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== paramspider ==="

echo "-- dry-run --"
dry "domain crawl"       "$DOMAIN" "-d $DOMAIN"
dry "with subs"          "$DOMAIN" "-d $DOMAIN -s"
dry "exclude extensions" "$DOMAIN" "-d $DOMAIN --exclude jpg,png,gif,css"
dry "output file"        "$DOMAIN" "-d $DOMAIN -o /tmp/paramspider_$DOMAIN.txt"
dry "level deep"         "$DOMAIN" "-d $DOMAIN -l 3"
dry "quiet mode"         "$DOMAIN" "-d $DOMAIN -q"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
