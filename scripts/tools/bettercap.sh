#!/bin/bash
# Tool: bettercap
# Skill: skills/bettercap/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: MITM framework — ARP spoofing, sniffer, proxy, BLE, WiFi
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"bettercap\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== bettercap ==="

echo "-- dry-run --"
dry "ARP spoof + sniff"    "-iface eth0 -eval 'set arp.spoof.targets $TARGET; arp.spoof on; net.sniff on'"
dry "HTTP proxy"           "-iface eth0 -eval 'set http.proxy.script /tmp/inject.js; http.proxy on'"
dry "HTTPS proxy"          "-iface eth0 -eval 'https.proxy on'"
dry "DNS spoof"            "-iface eth0 -eval 'set dns.spoof.domains evil.com; dns.spoof on'"
dry "credential sniff"     "-iface eth0 -eval 'net.sniff on'"
dry "WiFi recon"           "-iface wlan0mon -eval 'wifi.recon on'"
dry "BLE recon"            "-eval 'ble.recon on'"
dry "net probe"            "-iface eth0 -eval 'net.probe on'"
dry "caplet file"          "-iface eth0 -caplet /usr/share/bettercap/caplets/http-ui.cap"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
