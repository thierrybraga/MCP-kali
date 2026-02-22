#!/bin/bash
# Tool: amass
# Skill: skills/amass/SKILL.md
# Endpoint: POST /api/recon/amass
# Descrição: Enumeração avançada de subdomínios e mapeamento de superfície de ataque
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
DOMAIN="${TEST_DOMAIN:-example.com}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

recon() {
  local desc="$1"; local domain="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/recon/amass" \
    -H "Content-Type: application/json" \
    -d "{\"domain\":\"$domain\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local domain="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"amass\",\"target\":\"$domain\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== amass ==="

echo "-- dry-run --"
dry "passive enum"     "$DOMAIN" "enum -passive -d $DOMAIN -silent"
dry "active enum"      "$DOMAIN" "enum -active -d $DOMAIN -ip -src"
dry "brute force DNS"  "$DOMAIN" "enum -brute -d $DOMAIN -w /usr/share/wordlists/subdomains.txt"
dry "intel org"        "$DOMAIN" "intel -org \"Example Corp\" -whois"
dry "intel ASN"        "$DOMAIN" "intel -asn 15169"
dry "intel CIDR"       "$DOMAIN" "intel -cidr 192.168.0.0/16"
dry "json output"      "$DOMAIN" "enum -active -d $DOMAIN -json /tmp/amass.json -ip -src -timeout 30"
dry "with resolvers"   "$DOMAIN" "enum -passive -d $DOMAIN -r 8.8.8.8,1.1.1.1 -o /tmp/amass_subs.txt"

echo ""
echo "-- endpoint /api/recon/amass --"
recon "passive enum real" "$DOMAIN" "enum -passive -d $DOMAIN -silent"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
