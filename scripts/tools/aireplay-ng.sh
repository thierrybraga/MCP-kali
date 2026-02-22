#!/bin/bash
# Tool: aireplay-ng
# Skill: skills/aireplay-ng/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Injeção de pacotes wireless — deauth, ARP replay, fake auth
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"aireplay-ng\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== aireplay-ng ==="

echo "-- dry-run: deauth --"
dry "deauth broadcast"    "-0 5 -a AA:BB:CC:DD:EE:FF wlan0mon"
dry "deauth targeted"     "-0 10 -a AA:BB:CC:DD:EE:FF -c CC:DD:EE:FF:00:11 wlan0mon"
dry "deauth continuous"   "-0 0 -a AA:BB:CC:DD:EE:FF wlan0mon"

echo ""
echo "-- dry-run: WEP attacks --"
dry "fake authentication" "-1 0 -a AA:BB:CC:DD:EE:FF wlan0mon"
dry "ARP request replay"  "-3 -b AA:BB:CC:DD:EE:FF wlan0mon"
dry "chopchop attack"     "-4 -b AA:BB:CC:DD:EE:FF wlan0mon"
dry "fragmentation"       "-5 -b AA:BB:CC:DD:EE:FF wlan0mon"

echo ""
echo "-- dry-run: injection test --"
dry "injection test"      "-9 wlan0mon"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
