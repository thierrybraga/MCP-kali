#!/bin/bash
# Tool: dirsearch
# Skill: skills/dirsearch/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Brute force avançado de diretórios e arquivos web
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
    -d "{\"tool\":\"dirsearch\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== dirsearch ==="

echo "-- dry-run --"
dry "basic scan"         "http://$TARGET" "-u http://$TARGET"
dry "PHP extensions"     "http://$TARGET" "-u http://$TARGET -e php,html,txt"
dry "custom wordlist"    "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt"
dry "filter 404"         "http://$TARGET" "-u http://$TARGET --exclude-status 404"
dry "json report"        "http://$TARGET" "-u http://$TARGET --format json -o /tmp/dirsearch_$TARGET.json"
dry "with proxy"         "http://$TARGET" "-u http://$TARGET --proxy http://127.0.0.1:8080"
dry "threads"            "http://$TARGET" "-u http://$TARGET -t 50"
dry "recursive"          "http://$TARGET" "-u http://$TARGET -r --max-recursion-depth 3"
dry "multi URL"          ""               "-l /tmp/urls.txt -e php,txt"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
