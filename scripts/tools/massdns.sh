#!/bin/bash
# Tool: massdns
# Skill: skills/massdns/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Resolução DNS em massa de alta performance
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
    -d "{\"tool\":\"massdns\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== massdns ==="

echo "-- dry-run --"
dry "resolve list"       ""  "-r /usr/share/massdns/resolvers.txt -t A /tmp/subdomains.txt"
dry "json output"        ""  "-r /usr/share/massdns/resolvers.txt -t A -o J /tmp/subdomains.txt"
dry "simple output"      ""  "-r /usr/share/massdns/resolvers.txt -t A -o S /tmp/subdomains.txt"
dry "high rate"          ""  "-r /usr/share/massdns/resolvers.txt -t A -s 10000 /tmp/subdomains.txt"
dry "AAAA records"       ""  "-r /usr/share/massdns/resolvers.txt -t AAAA /tmp/subdomains.txt"
dry "with output file"   ""  "-r /usr/share/massdns/resolvers.txt -t A -o J -w /tmp/massdns_out.json /tmp/subdomains.txt"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
