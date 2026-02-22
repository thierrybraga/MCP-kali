#!/bin/bash
# Tool: waybackurls
# Skill: skills/waybackurls/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Extração de URLs do Wayback Machine para reconhecimento
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
    -d "{\"tool\":\"waybackurls\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== waybackurls ==="

echo "-- dry-run --"
dry "fetch URLs"         "$DOMAIN" "$DOMAIN"
dry "with dates"         "$DOMAIN" "-dates $DOMAIN"
dry "no subs"            "$DOMAIN" "-no-subs $DOMAIN"
dry "get versions"       "$DOMAIN" "-get-versions $DOMAIN"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
