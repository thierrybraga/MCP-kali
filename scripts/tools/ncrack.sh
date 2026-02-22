#!/bin/bash
# Tool: ncrack
# Skill: skills/ncrack/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Autenticação de rede brute force de alta velocidade (Nmap project)
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"ncrack\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== ncrack ==="

echo "-- dry-run --"
dry "SSH brute"           "$TARGET" "-U /tmp/users.txt -P /tmp/pass.txt ssh://$TARGET"
dry "RDP brute"           "$TARGET" "-U /tmp/users.txt -P /tmp/pass.txt rdp://$TARGET"
dry "FTP brute"           "$TARGET" "-U /tmp/users.txt -P /tmp/pass.txt ftp://$TARGET"
dry "SMB brute"           "$TARGET" "-U /tmp/users.txt -P /tmp/pass.txt smb://$TARGET"
dry "Telnet brute"        "$TARGET" "-U /tmp/users.txt -P /tmp/pass.txt telnet://$TARGET"
dry "VNC brute"           "$TARGET" "-P /tmp/pass.txt vnc://$TARGET"
dry "timing insane"       "$TARGET" "-T5 -U /tmp/users.txt -P /tmp/pass.txt ssh://$TARGET"
dry "multi service"       "$TARGET" "-U /tmp/u.txt -P /tmp/p.txt ssh://$TARGET rdp://$TARGET ftp://$TARGET"
dry "verbose output"      "$TARGET" "-v -U /tmp/u.txt -P /tmp/p.txt ssh://$TARGET"
dry "save output"         "$TARGET" "-U /tmp/u.txt -P /tmp/p.txt ssh://$TARGET -oN /tmp/ncrack_$TARGET.txt"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
