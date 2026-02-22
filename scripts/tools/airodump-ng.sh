#!/bin/bash
# Tool: airodump-ng
# Skill: skills/airodump-ng/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Captura de pacotes wireless — APs, clientes, handshakes, IVs
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
    -d "{\"tool\":\"airodump-ng\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== airodump-ng ==="

echo "-- dry-run --"
dry "scan all APs"           "wlan0mon"
dry "target AP"              "--bssid AA:BB:CC:DD:EE:FF -c 6 -w /root/captures/target wlan0mon"
dry "5GHz band"              "--band a -w /root/captures/scan5g wlan0mon"
dry "both bands"             "--band abg wlan0mon"
dry "filter WPA2"            "--encrypt WPA2 -w /root/captures/wpa2 wlan0mon"
dry "IVs for WEP"            "--bssid AA:BB:CC:DD:EE:FF -c 11 --output-format ivs -w /root/captures/wep wlan0mon"
dry "pcap output"            "--bssid AA:BB:CC:DD:EE:FF -c 6 --output-format pcap -w /root/captures/pcap wlan0mon"
dry "write interval"         "--bssid AA:BB:CC:DD:EE:FF -c 6 -w /root/cap/t --write-interval 5 wlan0mon"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
