#!/bin/bash
# Tool: spiderfoot
# Skill: skills/spiderfoot/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Automação OSINT com 200+ módulos de inteligência
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
    -d "{\"tool\":\"spiderfoot\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== spiderfoot ==="

echo "-- dry-run --"
dry "scan domain"       "$DOMAIN" "-s $DOMAIN -t DOMAIN_NAME -q"
dry "scan IP"           "8.8.8.8"  "-s 8.8.8.8 -t IP_ADDRESS -q"
dry "passive only"      "$DOMAIN" "-s $DOMAIN -t DOMAIN_NAME -m sfp_hackertarget,sfp_crt -q"
dry "json output"       "$DOMAIN" "-s $DOMAIN -t DOMAIN_NAME -o json -q"
dry "csv output"        "$DOMAIN" "-s $DOMAIN -t DOMAIN_NAME -o csv -q"
dry "list modules"      ""        "-l"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
