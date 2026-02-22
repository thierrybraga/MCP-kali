#!/bin/bash
# Test: Forensics & Reverse Engineering tools dry-run
# Skills: autopsy, volatility, ghidra, binwalk, foremost, radare2, apktool, dex2jar, strings, exiftool
# Endpoint: POST /api/tools/dry-run
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry_with_target() {
  local tool="$1"; local target="$2"; local options="${3:-}"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"$tool\",\"target\":\"$target\",\"options\":\"$options\"}")
  echo "$R" | grep -q '"command"' \
    && pass "$tool: dry-run has command" \
    || fail "$tool: dry-run" "no command: $R"
}

dry_no_target() {
  local tool="$1"; local options="${2:-}"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"$tool\",\"options\":\"$options\"}")
  echo "$R" | grep -q '"command"' \
    && pass "$tool (no-target): dry-run has command" \
    || fail "$tool (no-target): dry-run" "no command: $R"
}

echo "=== Forensics & Reverse Engineering Tools (dry-run) ==="

echo "-- binwalk --"
dry_with_target "binwalk" "/tmp/firmware.bin" "-e"
dry_with_target "binwalk" "/tmp/firmware.bin" "-Me"

echo "-- foremost --"
dry_with_target "foremost" "/tmp/disk.img" "-o /tmp/foremost_out"
dry_with_target "foremost" "/tmp/disk.img" "-t jpg,pdf -o /tmp/output"

echo "-- strings --"
dry_with_target "strings" "/tmp/binary" "-a"
dry_with_target "strings" "/tmp/binary" "-n 8 -a"

echo "-- exiftool --"
dry_with_target "exiftool" "/tmp/document.pdf" ""
dry_with_target "exiftool" "/tmp/image.jpg" "-all="

echo "-- radare2 --"
dry_with_target "radare2" "/tmp/binary" "-A -q -c 'pdf @ main'"
dry_with_target "radare2" "/tmp/binary" "-q -c 'iz'"

echo "-- apktool --"
dry_with_target "apktool" "/tmp/app.apk" "d"
dry_with_target "apktool" "/tmp/decompiled/" "b"

echo "-- dex2jar --"
dry_with_target "dex2jar" "/tmp/app.dex" ""
dry_with_target "dex2jar" "/tmp/classes.dex" "-o /tmp/output.jar"

echo "-- volatility --"
dry_no_target "volatility" "-f /tmp/memory.dmp imageinfo"
dry_no_target "volatility" "-f /tmp/memory.dmp --profile=Win10x64 pslist"
dry_no_target "volatility" "-f /tmp/memory.dmp --profile=Win10x64 netscan"
dry_no_target "volatility" "-f /tmp/memory.dmp --profile=Win10x64 hashdump"

echo "-- autopsy --"
dry_no_target "autopsy" ""

echo "-- ghidra --"
dry_no_target "ghidra" ""

echo "-- john --"
R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
  -H "Content-Type: application/json" \
  -d '{"tool":"john","target":"/tmp/shadow.txt","options":"--wordlist=/root/wordlists/rockyou.txt"}')
echo "$R" | grep -q '"command"' \
  && pass "john: dry-run has command" \
  || fail "john: dry-run" "no command"

echo "-- hashcat --"
R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
  -H "Content-Type: application/json" \
  -d '{"tool":"hashcat","target":"/tmp/ntlm.txt","options":"-m 1000 -a 0 /tmp/ntlm.txt /root/wordlists/rockyou.txt"}')
echo "$R" | grep -q '"command"' \
  && pass "hashcat: dry-run has command" \
  || fail "hashcat: dry-run" "no command"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
