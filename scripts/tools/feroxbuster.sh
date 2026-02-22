#!/bin/bash
# Tool: feroxbuster
# Skill: skills/feroxbuster/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Scanner de diretórios em Rust com recursão automática e alta performance
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
    -d "{\"tool\":\"feroxbuster\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== feroxbuster ==="

echo "-- dry-run --"
dry "basic scan"         "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt"
dry "with extensions"    "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -x php,txt,html"
dry "depth limit"        "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -d 3"
dry "no recursion"       "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -n"
dry "filter size"        "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt --filter-size 0"
dry "filter status"      "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt --filter-status 404"
dry "json output"        "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -o /tmp/ferox.json --json"
dry "threads"            "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -t 100"
dry "with proxy"         "http://$TARGET" "-u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -p http://127.0.0.1:8080"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
