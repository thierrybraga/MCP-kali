#!/bin/bash
# Tool: gobuster
# Skill: skills/gobuster/SKILL.md
# Endpoint: POST /api/web/gobuster
# Descrição: Brute force de diretórios, DNS e vhosts em Go (rápido)
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
DOMAIN="${TEST_DOMAIN:-example.com}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

scan() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/web/gobuster" \
    -H "Content-Type: application/json" \
    -d "$body") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"gobuster\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== gobuster ==="

echo "-- dry-run: dir mode --"
dry "dir common.txt"    "http://$TARGET" "dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt"
dry "dir + extensions"  "http://$TARGET" "dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -x php,html,txt"
dry "dir 50 threads"    "http://$TARGET" "dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -t 50"
dry "dir status filter" "http://$TARGET" "dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -s 200,301,302"
dry "dir output"        "http://$TARGET" "dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -o /tmp/gobuster_dir.txt"

echo ""
echo "-- dry-run: dns mode --"
dry "dns subdomains"    "$DOMAIN" "dns -d $DOMAIN -w /usr/share/wordlists/subdomains.txt"
dry "dns with IPs"      "$DOMAIN" "dns -d $DOMAIN -w /usr/share/wordlists/subdomains.txt -i"

echo ""
echo "-- dry-run: vhost mode --"
dry "vhost enum"        "http://$TARGET" "vhost -u http://$TARGET -w /usr/share/wordlists/vhosts.txt"

echo ""
echo "-- endpoint /api/web/gobuster --"
scan "dir scan" "{\"url\":\"http://$TARGET\",\"wordlist\":\"/usr/share/wordlists/dirb/common.txt\",\"mode\":\"dir\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
