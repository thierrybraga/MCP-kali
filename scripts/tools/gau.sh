#!/bin/bash
# Tool: gau
# Skill: skills/gau/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Coleta de URLs históricas via Wayback Machine, OTX e Common Crawl
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
    -d "{\"tool\":\"gau\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== gau ==="

echo "-- dry-run --"
dry "basic fetch"         "$DOMAIN" "$DOMAIN"
dry "with providers"      "$DOMAIN" "--providers wayback,otx,commoncrawl $DOMAIN"
dry "filter extensions"   "$DOMAIN" "--blacklist png,jpg,gif,css,woff $DOMAIN"
dry "output file"         "$DOMAIN" "--o /tmp/gau_$DOMAIN.txt $DOMAIN"
dry "json output"         "$DOMAIN" "--json $DOMAIN"
dry "from file"           ""        "--fc 404 $DOMAIN"
dry "subdomain urls"      "$DOMAIN" "--subs $DOMAIN"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
