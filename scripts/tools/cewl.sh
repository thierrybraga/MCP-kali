#!/bin/bash
# Tool: cewl
# Skill: skills/cewl/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Geração de wordlists customizadas via spider de sites alvo
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
    -d "{\"tool\":\"cewl\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== cewl ==="

echo "-- dry-run --"
dry "basic wordlist"       "http://$TARGET" "http://$TARGET"
dry "min word length 6"    "http://$TARGET" "-m 6 http://$TARGET"
dry "depth 3 crawl"        "http://$TARGET" "-d 3 http://$TARGET"
dry "include emails"       "http://$TARGET" "-e -m 5 http://$TARGET"
dry "output file"          "http://$TARGET" "-m 6 -w /tmp/cewl_wordlist.txt http://$TARGET"
dry "with metadata"        "http://$TARGET" "--meta -m 5 http://$TARGET"
dry "depth + output"       "http://$TARGET" "-d 2 -m 8 -w /tmp/cewl_deep.txt http://$TARGET"
dry "with auth"            "http://$TARGET" "--auth_type basic --auth_user admin --auth_pass pass http://$TARGET"
dry "lowercase only"       "http://$TARGET" "-m 6 --lowercase -w /tmp/cewl_lower.txt http://$TARGET"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
