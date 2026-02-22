#!/bin/bash
# Tool: nmap
# Skill: skills/nmap/SKILL.md
# Endpoint: POST /api/scan/nmap
# Descrição: Scanner de portas, serviços e vulnerabilidades com NSE
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

scan() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/scan/nmap" \
    -H "Content-Type: application/json" \
    -d "{\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected response: $R"
}

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"nmap\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== nmap ==="

echo "-- dry-run: variações de scan --"
dry "ping scan (dry)"        "$TARGET" "-sn"
dry "top ports SYN (dry)"    "$TARGET" "-sS --top-ports 100 -T4"
dry "service version (dry)"  "$TARGET" "-sV -sC --top-ports 1000 -T4"
dry "full port scan (dry)"   "$TARGET" "-p- -T4"
dry "OS detection (dry)"     "$TARGET" "-O -sV"
dry "aggressive scan (dry)"  "$TARGET" "-A -T4"
dry "vuln scripts (dry)"     "$TARGET" "--script vuln -sV"
dry "UDP scan (dry)"         "$TARGET" "-sU -p 53,161,500,1900"
dry "stealth scan (dry)"     "$TARGET" "-sS -T2 -Pn --data-length 15"
dry "CIDR scan (dry)"        "192.168.1.0/24" "-sn"
dry "NSE http (dry)"         "$TARGET" "--script http-title,http-headers -p 80,443,8080"
dry "NSE smb (dry)"          "$TARGET" "--script smb-enum-shares,smb-os-discovery -p 445"
dry "NSE ftp (dry)"          "$TARGET" "--script ftp-anon,ftp-bounce -p 21"
dry "NSE ssh (dry)"          "$TARGET" "--script ssh-auth-methods -p 22"
dry "output xml (dry)"       "$TARGET" "-sV -oX /tmp/nmap_scan.xml --top-ports 1000"

echo ""
echo "-- execução real --"
scan "ping sweep real"       "$TARGET" "-sn -T4"
scan "top 100 ports real"    "$TARGET" "--top-ports 100 -T4 -Pn"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
