#!/bin/bash
# Tool: recon-ng
# Skill: skills/recon-ng/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Framework modular de reconhecimento OSINT
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
    -d "{\"tool\":\"recon-ng\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== recon-ng ==="

echo "-- dry-run --"
dry "show modules"     ""       "--no-check -x 'show modules'"
dry "hackertarget"     "$DOMAIN" "--no-check -x 'use recon/domains-hosts/hackertarget; set SOURCE $DOMAIN; run'"
dry "bing domain"      "$DOMAIN" "--no-check -x 'use recon/domains-hosts/bing_domain_web; set SOURCE $DOMAIN; run'"
dry "shodan hostname"  "$DOMAIN" "--no-check -x 'use recon/hosts-hosts/shodan_hostname; set SOURCE $DOMAIN; run'"
dry "csv report"       "$DOMAIN" "--no-check -x 'use reporting/csv; set FILENAME /tmp/recon_report.csv; run'"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
