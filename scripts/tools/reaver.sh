#!/bin/bash
# Tool: reaver
# Skill: skills/reaver/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Brute force de PIN WPS para recuperar chave WPA/WPA2
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
    -d "{\"tool\":\"reaver\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== reaver ==="

echo "-- dry-run --"
dry "basic WPS attack"   "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -vv"
dry "with delay"         "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -d 15 -r 3:15"
dry "pixie dust mode"    "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -K 1"
dry "no associated"      "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -A"
dry "session save"       "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -s /tmp/reaver_session"
dry "max attempts"       "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -m 10 -vv"
dry "timeout 5s"         "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -t 5 -vv"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
