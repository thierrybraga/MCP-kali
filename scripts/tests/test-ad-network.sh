#!/bin/bash
# Test: Active Directory & Network tools dry-run
# Skills: crackmapexec, responder, bloodhound, ldapdomaindump, impacket, enum4linux
# Endpoint: POST /api/tools/dry-run
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local tool="$1"; local target="${2:-}"; local options="${3:-}"
  local BODY
  if [ -n "$target" ]; then
    BODY="{\"tool\":\"$tool\",\"target\":\"$target\",\"options\":\"$options\"}"
  else
    BODY="{\"tool\":\"$tool\",\"options\":\"$options\"}"
  fi
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" -d "$BODY")
  echo "$R" | grep -q '"command"' \
    && pass "$tool: dry-run has command" \
    || fail "$tool: dry-run" "no command: $R"
}

echo "=== Active Directory & Network Tools (dry-run) ==="

echo "-- crackmapexec --"
dry "crackmapexec" "" "smb 192.168.1.0/24"
dry "crackmapexec" "" "smb 192.168.1.100 -u admin -p Password123 --shares"
dry "crackmapexec" "" "smb 192.168.1.100 -u admin -p Password123 --sam"
dry "crackmapexec" "" "smb 192.168.1.100 -u admin -p Password123 --ntds"
dry "crackmapexec" "" "ldap 192.168.1.10 -u admin -p Password123 --users"
dry "crackmapexec" "" "winrm 192.168.1.100 -u admin -p Password123 -x whoami"

echo "-- responder --"
dry "responder" "" "-I eth0 -rdwv"
dry "responder" "" "-I eth0 -A"
dry "responder" "" "-I eth0 --lm"

echo "-- bloodhound-python --"
dry "bloodhound-python" "" "-d CORP.LOCAL -u john -p Password123 --dc 192.168.1.10 -c All --zip"
dry "bloodhound-python" "" "-d CORP.LOCAL -u john -p Password123 --dc 192.168.1.10 -c DCOnly --zip"

echo "-- ldapdomaindump --"
dry "ldapdomaindump" "192.168.1.10" "-u 'CORP\\admin' -p Password123"

echo "-- impacket --"
dry "impacket" "" "secretsdump.py CORP/admin:Password123@192.168.1.10"
dry "impacket" "" "psexec.py CORP/admin:Password123@192.168.1.100"
dry "impacket" "" "GetNPUsers.py CORP/ -usersfile users.txt -no-pass -format hashcat"

echo "-- enum4linux --"
dry "enum4linux" "192.168.1.100" "-a"
dry "enum4linux" "192.168.1.100" "-U -G -S -P"

echo "-- smtp-user-enum --"
dry "smtp-user-enum" "192.168.1.100" "-M VRFY -u admin -t 192.168.1.100"

echo "-- snmp-check --"
dry "snmp-check" "192.168.1.100" "-c public"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
