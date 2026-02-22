#!/bin/bash
# Tool: hydra
# Skill: skills/hydra/SKILL.md
# Endpoint: POST /api/bruteforce/hydra
# Descrição: Brute force multi-protocolo (SSH, FTP, HTTP, RDP, SMB, MySQL...)
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

bf() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/bruteforce/hydra" \
    -H "Content-Type: application/json" \
    -d "$body") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"hydra\",\"target\":\"$TARGET\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== hydra ==="

echo "-- dry-run --"
dry "SSH brute"           "-l root -P /usr/share/wordlists/rockyou.txt -t 4 -f $TARGET ssh"
dry "FTP brute"           "-L /tmp/users.txt -P /tmp/pass.txt -t 8 $TARGET ftp"
dry "RDP brute"           "-l administrator -P /tmp/pass.txt -t 4 $TARGET rdp"
dry "HTTP POST form"      "-l admin -P /tmp/pass.txt $TARGET http-post-form '/login.php:user=^USER^&pass=^PASS^:Invalid'"
dry "SMB brute"           "-L /tmp/users.txt -P /tmp/pass.txt $TARGET smb"
dry "MySQL brute"         "-l root -P /tmp/pass.txt $TARGET mysql"
dry "SMTP brute"          "-l admin@corp.com -P /tmp/pass.txt $TARGET smtp"
dry "VNC brute"           "-P /tmp/pass.txt $TARGET vnc"
dry "telnet brute"        "-l admin -P /tmp/pass.txt $TARGET telnet"
dry "trivial extras"      "-l admin -e nsr -t 4 $TARGET ssh"
dry "multi hosts"         "-l admin -P /tmp/pass.txt -M /tmp/hosts.txt ssh"
dry "generate passwords"  "-l admin -x 4:6:aA1 -t 4 $TARGET ssh"
dry "save output"         "-l root -P /tmp/pass.txt -t 4 -o /tmp/hydra_$TARGET.txt $TARGET ssh"

echo ""
echo "-- endpoint /api/bruteforce/hydra --"
bf "SSH root wordlist" "{\"target\":\"$TARGET\",\"service\":\"ssh\",\"username\":\"root\",\"passlist\":\"/usr/share/wordlists/rockyou.txt\",\"options\":\"-t 4 -f\"}"
bf "FTP with options"  "{\"target\":\"$TARGET\",\"service\":\"ftp\",\"username\":\"anonymous\",\"options\":\"-e n -t 4\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
