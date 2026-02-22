#!/bin/bash
# Tool: responder
# Skill: skills/responder/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: LLMNR/NBT-NS/MDNS poisoning para captura de hashes Net-NTLMv2
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
    -d "{\"tool\":\"responder\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== responder ==="

echo "-- dry-run --"
dry "full poisoning"    "-I eth0 -rdwv"
dry "analyze only"      "-I eth0 -A"
dry "LM downgrade"      "-I eth0 --lm"
dry "WPAD poisoning"    "-I eth0 -wPv"
dry "disable SMB"       "-I eth0 -rdwv --disable-ess"
dry "custom challenge"  "-I eth0 -rdwv --challenge 1122334455667788"
dry "WiFi interface"    "-I wlan0 -rdwv"
dry "verbose + logs"    "-I eth0 -rdwv --lm -F --verbose"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
