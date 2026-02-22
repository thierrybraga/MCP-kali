#!/bin/bash
# Test: Sniffing / MITM tools dry-run
# Skills: bettercap, mitmf, driftnet, yersinia, responder
# Endpoint: POST /api/tools/dry-run
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local tool="$1"; local options="${2:-}"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"$tool\",\"options\":\"$options\"}")
  echo "$R" | grep -q '"command"' \
    && pass "$tool: dry-run has command" \
    || fail "$tool: dry-run" "no command: $R"
}

echo "=== Sniffing & MITM Tools (dry-run) ==="

echo "-- bettercap --"
dry "bettercap" "-iface eth0 -eval 'net.probe on'"
dry "bettercap" "-iface eth0 --caplet /root/scripts/arp_spoof.cap"

echo "-- mitmf --"
dry "mitmf" "--interface eth0 --arp --spoof --gateway 192.168.1.1 --target 192.168.1.0/24"

echo "-- driftnet --"
dry "driftnet" "-i eth0"
dry "driftnet" "-i eth0 -a -d /tmp/driftnet_output"

echo "-- yersinia --"
dry "yersinia" "-G"
dry "yersinia" "-I -a stp"

echo "-- responder --"
dry "responder" "-I eth0 -rdwv"
dry "responder" "-I eth0 -A"

echo "-- sslstrip --"
dry "sslstrip" "-l 10000"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
