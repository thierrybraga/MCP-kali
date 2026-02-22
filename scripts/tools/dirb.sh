#!/bin/bash
# Tool: dirb
# Skill: skills/dirb/SKILL.md
# Endpoint: POST /api/web/dirb
# Descrição: Brute force de diretórios e arquivos em servidores web
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

scan() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/web/dirb" \
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
    -d "{\"tool\":\"dirb\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== dirb ==="

echo "-- dry-run --"
dry "default wordlist"   "http://$TARGET" "http://$TARGET"
dry "custom wordlist"    "http://$TARGET" "http://$TARGET /usr/share/wordlists/dirb/common.txt"
dry "extensions"         "http://$TARGET" "http://$TARGET -X .php,.html,.txt"
dry "recursive"          "http://$TARGET" "http://$TARGET -r"
dry "output file"        "http://$TARGET" "http://$TARGET -o /tmp/dirb_$TARGET.txt"
dry "ignore codes"       "http://$TARGET" "http://$TARGET -N 404"
dry "with cookies"       "http://$TARGET" "http://$TARGET -c 'PHPSESSID=abc123'"
dry "HTTPS"              "https://$TARGET" "https://$TARGET"
dry "basic auth"         "http://$TARGET" "http://$TARGET -u admin:password"

echo ""
echo "-- endpoint /api/web/dirb --"
scan "basic scan" "{\"url\":\"http://$TARGET\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
