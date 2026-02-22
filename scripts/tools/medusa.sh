#!/bin/bash
# Tool: medusa
# Skill: skills/medusa/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Brute force paralelo de rede com suporte a múltiplos módulos
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
    -d "{\"tool\":\"medusa\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== medusa ==="

echo "-- dry-run --"
dry "SSH brute"           "-h $TARGET -u root -P /usr/share/wordlists/rockyou.txt -M ssh -t 4 -f"
dry "FTP brute"           "-h $TARGET -U /tmp/users.txt -P /tmp/pass.txt -M ftp -t 8 -f"
dry "MySQL brute"         "-h $TARGET -u root -P /tmp/pass.txt -M mysql -f"
dry "SMB brute"           "-h $TARGET -U /tmp/users.txt -P /tmp/pass.txt -M smbnt -f"
dry "RDP brute"           "-h $TARGET -u administrator -P /tmp/pass.txt -M rdp -t 4 -f"
dry "POP3 brute"          "-h $TARGET -u admin -P /tmp/pass.txt -M pop3 -f"
dry "IMAP brute"          "-h $TARGET -u admin -P /tmp/pass.txt -M imap -f"
dry "Telnet brute"        "-h $TARGET -u admin -P /tmp/pass.txt -M telnet -f"
dry "multi host file"     "-H /tmp/hosts.txt -u admin -P /tmp/pass.txt -M ssh -T 10"
dry "list modules"        "-d"
dry "verbose output"      "-h $TARGET -u root -P /tmp/pass.txt -M ssh -v 6 -f"
dry "save output"         "-h $TARGET -u root -P /tmp/pass.txt -M ssh -f -O /tmp/medusa_$TARGET.txt"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
