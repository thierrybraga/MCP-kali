#!/bin/bash
# Tool: dmitry
# Skill: skills/dmitry/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: OSINT: whois, subdomínios, emails, portas e netcraft
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
    -d "{\"tool\":\"dmitry\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== dmitry ==="

echo "-- dry-run --"
dry "whois lookup"      "$DOMAIN" "-w $DOMAIN"
dry "subdomain search"  "$DOMAIN" "-s $DOMAIN"
dry "email search"      "$DOMAIN" "-e $DOMAIN"
dry "full scan"         "$DOMAIN" "-wse $DOMAIN"
dry "port scan"         "$DOMAIN" "-p $DOMAIN"
dry "netcraft"          "$DOMAIN" "-n $DOMAIN"
dry "all + output"      "$DOMAIN" "-winsepbo /tmp/dmitry_$DOMAIN.txt $DOMAIN"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
