#!/bin/bash
# Tool: masscan
# Skill: skills/masscan/SKILL.md
# Endpoint: POST /api/scan/masscan
# Descrição: Scanner de portas ultra-rápido baseado em transmissão assíncrona
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"masscan\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

scan() {
  local desc="$1"; local target="$2"; local ports="$3"; local rate="$4"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/scan/masscan" \
    -H "Content-Type: application/json" \
    -d "{\"target\":\"$target\",\"ports\":\"$ports\",\"rate\":$rate}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

echo "=== masscan ==="

echo "-- dry-run --"
dry "top ports rate 1000"  "$TARGET"        "-p 80,443,22,21,25 --rate 1000"
dry "all ports rate 10000" "192.168.1.0/24" "-p 0-65535 --rate 10000"
dry "web ports"            "10.0.0.0/24"    "-p 80,443,8080,8443,8888 --rate 5000"
dry "common services"      "$TARGET"        "-p 21,22,23,25,53,80,110,143,443,445,3306,3389 --rate 2000"
dry "output json"          "$TARGET"        "-p 1-1024 --rate 1000 -oJ /tmp/masscan.json"
dry "output xml"           "$TARGET"        "-p 80,443 --rate 500 -oX /tmp/masscan.xml"
dry "banners"              "$TARGET"        "-p 80,22 --banners --rate 100"
dry "exclude range"        "10.0.0.0/8"     "-p 80,443 --rate 5000 --exclude 10.0.0.1"

echo ""
echo "-- execução real --"
scan "masscan local port 80" "$TARGET" "80" 100

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
