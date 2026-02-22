#!/bin/bash
# Tool: dnsrecon
# Skill: skills/dnsrecon/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Enumeração DNS completa: zone transfer, brute force, registros, reverso
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
DOMAIN="${TEST_DOMAIN:-example.com}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"dnsrecon\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== dnsrecon ==="

echo "-- dry-run --"
dry "standard enum"       "$DOMAIN" "-d $DOMAIN"
dry "zone transfer"       "$DOMAIN" "-d $DOMAIN -t axfr"
dry "brute force DNS"     "$DOMAIN" "-d $DOMAIN -t brt -D /usr/share/wordlists/subdomains.txt"
dry "reverse lookup"      "$TARGET" "-r 192.168.1.0/24"
dry "all record types"    "$DOMAIN" "-d $DOMAIN -t std,rvl,brt,srv,axfr"
dry "google DNS"          "$DOMAIN" "-d $DOMAIN -n 8.8.8.8"
dry "json output"         "$DOMAIN" "-d $DOMAIN -j /tmp/dnsrecon_$DOMAIN.json"
dry "wildcard check"      "$DOMAIN" "-d $DOMAIN -t std --xml /tmp/dns.xml"
dry "SRV records"         "$DOMAIN" "-d $DOMAIN -t srv"
dry "cache snooping"      "$DOMAIN" "-t snoop -n 8.8.8.8 -D /tmp/names.txt"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
