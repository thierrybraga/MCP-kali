#!/bin/bash
# Tool: aircrack-ng
# Skill: skills/aircrack-ng/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Suite WiFi — captura, injeção, deauth e crack de WEP/WPA
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"aircrack-ng\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== aircrack-ng ==="

echo "-- dry-run: crack WPA --"
dry "WPA wordlist crack"    "/root/captures/handshake.cap"  "-w /usr/share/wordlists/rockyou.txt -b AA:BB:CC:DD:EE:FF /root/captures/handshake.cap"
dry "WPA multi BSSID"       "/root/captures/handshake.cap"  "-w /usr/share/wordlists/rockyou.txt /root/captures/handshake.cap"
dry "WPA quiet mode"        "/root/captures/handshake.cap"  "-q -w /usr/share/wordlists/rockyou.txt /root/captures/handshake.cap"
dry "WPA save key"          "/root/captures/handshake.cap"  "-w /usr/share/wordlists/rockyou.txt -l /tmp/wpa_key.txt /root/captures/handshake.cap"

echo ""
echo "-- dry-run: crack WEP --"
dry "WEP IVs file"          "/root/captures/wep.ivs"        "/root/captures/wep.ivs"
dry "WEP CAP file"          "/root/captures/wep.cap"        "-b AA:BB:CC:DD:EE:FF /root/captures/wep.cap"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
