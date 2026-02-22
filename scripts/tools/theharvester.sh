#!/bin/bash
# Tool: theharvester
# Skill: skills/theharvester/SKILL.md
# Endpoint: POST /api/recon/theharvester
# Descrição: Coleta de emails, subdomínios, IPs e nomes de funcionários via OSINT
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
DOMAIN="${TEST_DOMAIN:-example.com}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

recon() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/recon/theharvester" \
    -H "Content-Type: application/json" \
    -d "$body") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"theharvester\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== theharvester ==="

echo "-- dry-run --"
dry "google source"     "$DOMAIN" "-d $DOMAIN -b google -l 100"
dry "bing source"       "$DOMAIN" "-d $DOMAIN -b bing -l 50"
dry "linkedin source"   "$DOMAIN" "-d $DOMAIN -b linkedin"
dry "all sources"       "$DOMAIN" "-d $DOMAIN -b all -l 200"
dry "xml output"        "$DOMAIN" "-d $DOMAIN -b google -f /tmp/harvest_$DOMAIN -l 100"
dry "shodan source"     "$DOMAIN" "-d $DOMAIN -b shodan"
dry "virustotal"        "$DOMAIN" "-d $DOMAIN -b virustotal"
dry "with DNS brute"    "$DOMAIN" "-d $DOMAIN -b google -c -l 100"

echo ""
echo "-- endpoint real --"
recon "google harvest" "{\"domain\":\"$DOMAIN\",\"source\":\"google\",\"limit\":50}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
