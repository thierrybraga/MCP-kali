#!/bin/bash
# Tool: assetfinder
# Skill: skills/assetfinder/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Descoberta rápida de subdomínios e assets via fontes OSINT
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
    -d "{\"tool\":\"assetfinder\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== assetfinder ==="

echo "-- dry-run --"
dry "basic domain"     "$DOMAIN" "--subs-only $DOMAIN"
dry "all assets"       "$DOMAIN" "$DOMAIN"
dry "pipe to httpx"    "$DOMAIN" "--subs-only $DOMAIN"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
