#!/bin/bash
# Tool: subfinder
# Skill: skills/subfinder/SKILL.md
# Endpoint: POST /api/recon/subfinder
# Descrição: Enumeração passiva de subdomínios via fontes OSINT
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
DOMAIN="${TEST_DOMAIN:-example.com}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

recon() {
  local desc="$1"; local domain="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/recon/subfinder" \
    -H "Content-Type: application/json" \
    -d "{\"domain\":\"$domain\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"subfinder\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== subfinder ==="

echo "-- dry-run --"
dry "basic scan"        "$DOMAIN" "-d $DOMAIN -silent"
dry "verbose output"    "$DOMAIN" "-d $DOMAIN -v"
dry "with IPs"          "$DOMAIN" "-d $DOMAIN -silent -oI /tmp/sf_ips.txt"
dry "json output"       "$DOMAIN" "-d $DOMAIN -oJ /tmp/sf_results.json"
dry "multi source"      "$DOMAIN" "-d $DOMAIN -all -silent"
dry "rate limit"        "$DOMAIN" "-d $DOMAIN -t 10 -silent"
dry "output file"       "$DOMAIN" "-d $DOMAIN -o /tmp/sf_subs.txt"
dry "recursive"         "$DOMAIN" "-d $DOMAIN -recursive -silent"

echo ""
echo "-- endpoint real --"
recon "subfinder passive" "$DOMAIN" "-d $DOMAIN -silent"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
