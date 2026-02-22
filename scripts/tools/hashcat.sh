#!/bin/bash
# Tool: hashcat
# Skill: skills/hashcat/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Crack de hashes acelerado por GPU com múltiplos modos de ataque
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"hashcat\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== hashcat ==="

echo "-- dry-run: modos de ataque --"
dry "MD5 wordlist"        "/tmp/hashes.txt"  "-m 0 -a 0 /tmp/hashes.txt /usr/share/wordlists/rockyou.txt"
dry "NTLM wordlist"       "/tmp/ntlm.txt"    "-m 1000 -a 0 /tmp/ntlm.txt /usr/share/wordlists/rockyou.txt"
dry "SHA1 wordlist"       "/tmp/sha1.txt"    "-m 100 -a 0 /tmp/sha1.txt /usr/share/wordlists/rockyou.txt"
dry "SHA256 wordlist"     "/tmp/sha256.txt"  "-m 1400 -a 0 /tmp/sha256.txt /usr/share/wordlists/rockyou.txt"
dry "bcrypt wordlist"     "/tmp/bcrypt.txt"  "-m 3200 -a 0 /tmp/bcrypt.txt /usr/share/wordlists/rockyou.txt"
dry "WPA2 PMKID"          "/tmp/pmkid.txt"   "-m 22000 -a 0 /tmp/pmkid.txt /usr/share/wordlists/rockyou.txt"
dry "Net-NTLMv2"          "/tmp/netntlm.txt" "-m 5600 -a 0 /tmp/netntlm.txt /usr/share/wordlists/rockyou.txt"
dry "Kerberoast TGS"      "/tmp/tgs.txt"     "-m 13100 -a 0 /tmp/tgs.txt /usr/share/wordlists/rockyou.txt"
dry "AS-REP Roast"        "/tmp/asrep.txt"   "-m 18200 -a 0 /tmp/asrep.txt /usr/share/wordlists/rockyou.txt"

echo ""
echo "-- dry-run: modos de crack --"
dry "mask attack"         "/tmp/hashes.txt"  "-m 0 -a 3 /tmp/hashes.txt ?u?l?l?l?d?d?d"
dry "wordlist + rules"    "/tmp/hashes.txt"  "-m 0 -a 0 /tmp/hashes.txt /tmp/wordlist.txt -r /usr/share/hashcat/rules/best64.rule"
dry "combination"         "/tmp/hashes.txt"  "-m 0 -a 1 /tmp/hashes.txt /tmp/list1.txt /tmp/list2.txt"
dry "show cracked"        "/tmp/hashes.txt"  "-m 0 --show /tmp/hashes.txt"
dry "benchmark"           ""                 "-b -m 0"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
