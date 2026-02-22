#!/bin/bash
# Tool: arjun
# Skill: skills/arjun/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Descoberta de parâmetros HTTP ocultos em endpoints web
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
    -d "{\"tool\":\"arjun\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== arjun ==="

echo "-- dry-run --"
dry "GET params"         "http://$TARGET" "-u http://$TARGET/api/endpoint -m GET"
dry "POST params"        "http://$TARGET" "-u http://$TARGET/api/endpoint -m POST"
dry "JSON body"          "http://$TARGET" "-u http://$TARGET/api/endpoint -m JSON"
dry "custom wordlist"    "http://$TARGET" "-u http://$TARGET/api/endpoint -w /usr/share/wordlists/params.txt"
dry "output JSON"        "http://$TARGET" "-u http://$TARGET/api/endpoint -oJ /tmp/arjun_params.json"
dry "stable rate"        "http://$TARGET" "-u http://$TARGET/api/endpoint --stable"
dry "multi URL"          ""               "-i /tmp/urls.txt -m GET"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
