#!/bin/bash
# Tool: msfconsole
# Skill: skills/msfconsole/SKILL.md
# Endpoint: POST /api/exploit/msfconsole
# Descrição: Automação do Metasploit Framework via API
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

msf() {
  local desc="$1"; local commands="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/exploit/msfconsole" \
    -H "Content-Type: application/json" \
    -d "{\"commands\":$commands}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

echo "=== msfconsole ==="

echo "-- endpoint /api/exploit/msfconsole --"
msf "version check"         '["version"]'
msf "list exploits"         '["show exploits"]'
msf "list payloads"         '["show payloads"]'
msf "search exploit"        '["search type:exploit platform:linux"]'
msf "multi/handler setup"   '["use exploit/multi/handler","set payload linux/x86/meterpreter/reverse_tcp","set LHOST '"$TARGET"'","set LPORT 4444","show options"]'
msf "reverse shell handler" '["use exploit/multi/handler","set payload windows/meterpreter/reverse_tcp","set LHOST '"$TARGET"'","set LPORT 4444","show options"]'
msf "SMB exploit search"    '["search ms17_010"]'
msf "DB nmap scan"          '["db_nmap -sV --top-ports 100 '"$TARGET"'"]'

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
