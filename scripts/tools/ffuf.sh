#!/bin/bash
# Tool: ffuf
# Skill: skills/ffuf/SKILL.md
# Endpoint: POST /api/web/ffuf
# Descrição: Fuzzer web ultra-rápido para diretórios, parâmetros e vhosts
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
  R=$(curl -sf -X POST "$BASE_URL/api/web/ffuf" \
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
    -d "{\"tool\":\"ffuf\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== ffuf ==="

echo "-- dry-run: directory fuzzing --"
dry "dir fuzz basic"    "http://$TARGET/FUZZ" "-u http://$TARGET/FUZZ -w /usr/share/wordlists/dirb/common.txt -v"
dry "dir with ext"      "http://$TARGET/FUZZ" "-u http://$TARGET/FUZZ -w /usr/share/wordlists/dirb/common.txt -e .php,.txt,.html"
dry "filter by size"    "http://$TARGET/FUZZ" "-u http://$TARGET/FUZZ -w /usr/share/dirb/common.txt -fs 0"
dry "filter by status"  "http://$TARGET/FUZZ" "-u http://$TARGET/FUZZ -w /usr/share/dirb/common.txt -fc 404"
dry "json output"       "http://$TARGET/FUZZ" "-u http://$TARGET/FUZZ -w /usr/share/dirb/common.txt -o /tmp/ffuf.json -of json"

echo ""
echo "-- dry-run: parameter fuzzing --"
dry "GET param fuzz"    "http://$TARGET" "-u http://$TARGET/page.php?FUZZ=value -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt"
dry "POST data fuzz"    "http://$TARGET" "-u http://$TARGET/login -X POST -d 'username=FUZZ&password=test' -w /usr/share/seclists/Usernames/Names/names.txt"

echo ""
echo "-- dry-run: vhost fuzzing --"
dry "vhost fuzz"        "http://$TARGET" "-u http://$TARGET -H 'Host: FUZZ.$DOMAIN' -w /usr/share/wordlists/vhosts.txt -fs 0"

echo ""
echo "-- endpoint /api/web/ffuf --"
scan "basic dir scan" "{\"url\":\"http://$TARGET/FUZZ\",\"wordlist\":\"/usr/share/wordlists/dirb/common.txt\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
