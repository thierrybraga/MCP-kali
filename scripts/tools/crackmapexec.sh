#!/bin/bash
# Tool: crackmapexec
# Skill: skills/crackmapexec/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Swiss army knife para pentests AD/SMB — enum, spray, exec, dump
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
    -d "{\"tool\":\"crackmapexec\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== crackmapexec ==="

echo "-- dry-run: SMB --"
dry "SMB discovery"       "smb 192.168.1.0/24"
dry "SMB enumerate"       "smb $TARGET -u admin -p Password123 --shares"
dry "SMB SAM dump"        "smb $TARGET -u admin -p Password123 --sam"
dry "SMB NTDS dump"       "smb $TARGET -u admin -p Password123 --ntds"
dry "SMB exec command"    "smb $TARGET -u admin -p Password123 -x whoami"
dry "SMB pass spray"      "smb 192.168.1.0/24 -u /tmp/users.txt -p Password123 --continue-on-success"
dry "SMB hash auth"       "smb $TARGET -u admin -H aad3b435b51404eeaad3b435b51404ee:NTLMHASH"
dry "SMB loggedon"        "smb $TARGET -u admin -p Password123 --loggedon-users"
dry "SMB spider shares"   "smb $TARGET -u admin -p Password123 --spider C\$"

echo ""
echo "-- dry-run: LDAP --"
dry "LDAP users"          "ldap $TARGET -u admin -p Password123 --users"
dry "LDAP groups"         "ldap $TARGET -u admin -p Password123 --groups"
dry "LDAP computers"      "ldap $TARGET -u admin -p Password123 --computers"
dry "LDAP ASREPRoast"     "ldap $TARGET -u admin -p Password123 --asreproast /tmp/asrep.txt"
dry "LDAP Kerberoast"     "ldap $TARGET -u admin -p Password123 --kerberoasting /tmp/kerb.txt"

echo ""
echo "-- dry-run: WinRM --"
dry "WinRM exec"          "winrm $TARGET -u admin -p Password123 -x whoami"

echo ""
echo "-- dry-run: SSH --"
dry "SSH brute spray"     "ssh $TARGET -u /tmp/users.txt -p /tmp/pass.txt"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
