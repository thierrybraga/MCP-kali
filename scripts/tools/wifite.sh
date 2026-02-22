#!/bin/bash
# Tool: wifite
# Skill: skills/wifite/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Ferramenta automatizada de auditoria WiFi (WPA/WEP/WPS)
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
    -d "{\"tool\":\"wifite\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== wifite ==="

echo "-- dry-run --"
dry "WPA targets"        "--wpa --kill"
dry "WPS targets"        "--wps --kill"
dry "WEP targets"        "--wep --kill"
dry "specific interface" "--interface wlan0 --wpa --kill"
dry "with wordlist"      "--wpa --wordlist /usr/share/wordlists/rockyou.txt --kill"
dry "PMKID attack"       "--pmkid --kill"
dry "min signal"         "--wpa --min-power -70 --kill"
dry "specific BSSID"     "--wpa --bssid AA:BB:CC:DD:EE:FF --kill"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
