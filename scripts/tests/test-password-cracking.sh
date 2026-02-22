#!/bin/bash
# Test: Password cracking tools dry-run
# Skills: medusa, john, hashcat, hydra, ncrack, cewl, crunch, ophcrack
# Endpoint: POST /api/tools/dry-run + POST /api/bruteforce/hydra
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

echo "=== Password Cracking Tools (dry-run) ==="

echo "-- medusa --"
dry "medusa" "" "-h 192.168.1.100 -u root -P /root/wordlists/rockyou.txt -M ssh -t 4 -f"
dry "medusa" "" "-H /root/targets/hosts.txt -u admin -P /root/wordlists/rockyou.txt -M ftp -T 5 -F"

echo "-- john --"
dry "john" "/tmp/shadow.txt" "--wordlist=/root/wordlists/rockyou.txt"
dry "john" "/tmp/ntlm.txt" "--format=NT --wordlist=/root/wordlists/rockyou.txt --rules=best64"
dry "john" "/tmp/shadow.txt" "--show"

echo "-- hashcat --"
dry "hashcat" "/tmp/ntlm.txt" "-m 1000 -a 0 /tmp/ntlm.txt /root/wordlists/rockyou.txt"
dry "hashcat" "/tmp/netntlmv2.txt" "-m 5600 -a 0 /tmp/netntlmv2.txt /root/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule"
dry "hashcat" "/tmp/kerberos.txt" "-m 13100 -a 0 /tmp/kerberos.txt /root/wordlists/rockyou.txt"

echo "-- ncrack --"
dry "ncrack" "192.168.1.100" "-p ssh"
dry "ncrack" "192.168.1.100" "-p rdp -u administrator -P /root/wordlists/rockyou.txt"

echo "-- cewl --"
dry "cewl" "http://target.com" "-d 2 -m 8 -o /root/wordlists/custom.txt"

echo "-- crunch --"
dry "crunch" "" "8 8 abc123 -o /root/wordlists/generated.txt"
dry "crunch" "" "4 8 -t @@@@%%%% -o /root/wordlists/pattern.txt"

echo "-- ophcrack --"
dry "ophcrack" "" "-t /tmp/tables -f /tmp/hashes.txt"

echo "-- hydra (via API dedicada) --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/bruteforce/hydra" \
  -H "Content-Type: application/json" \
  -d '{"target":"127.0.0.1","service":"ssh","username":"test","password":"test"}')
[ "$CODE" = "200" ] || [ "$CODE" = "500" ] \
  && pass "hydra: API endpoint reachable" \
  || fail "hydra: API" "got $CODE"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
