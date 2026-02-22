#!/bin/bash
# Tool: brutespray
# Skill: skills/brutespray/SKILL.md
# Endpoint: POST /api/bruteforce/brutespray
# Descrição: Brute force automatizado a partir de XML do Nmap via Medusa
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

bf() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/bruteforce/brutespray" \
    -H "Content-Type: application/json" \
    -d "$body") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"brutespray\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== brutespray ==="

echo "-- dry-run --"
dry "full auto attack"    "--file /tmp/scan.xml --threads 5 --hosts-per-service 3 --found-only -o /tmp/bs_results/"
dry "SSH+FTP only"        "--file /tmp/scan.xml --service ssh,ftp --threads 3 --found-only"
dry "custom wordlists"    "--file /tmp/scan.xml -U /tmp/users.txt -P /tmp/pass.txt --found-only"
dry "DB services"         "--file /tmp/scan.xml --service mysql,mssql,psql --threads 5 --found-only"
dry "dry-run no attack"   "--file /tmp/scan.xml --no-bruteforce --verbose"
dry "high parallelism"    "--file /tmp/scan.xml --threads 10 --hosts-per-service 5 --found-only"

echo ""
echo "-- endpoint /api/bruteforce/brutespray --"
bf "auto from nmap XML" "{\"target\":\"$TARGET\",\"options\":\"--file /tmp/scan.xml --threads 2 --found-only\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
