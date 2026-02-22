#!/bin/bash
# Tool: skipfish
# Skill: skills/skipfish/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Spider web ativo com análise de segurança e geração de relatório HTML
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
    -d "{\"tool\":\"skipfish\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== skipfish ==="

echo "-- dry-run --"
dry "basic scan"         "http://$TARGET" "-o /tmp/skipfish_$TARGET http://$TARGET"
dry "no extensions"      "http://$TARGET" "-o /tmp/skipfish_$TARGET -X .jpg,.png,.css,.js http://$TARGET"
dry "max requests"       "http://$TARGET" "-o /tmp/skipfish_$TARGET -l 1000 http://$TARGET"
dry "with auth cookie"   "http://$TARGET" "-o /tmp/skipfish_$TARGET -C 'PHPSESSID=abc' http://$TARGET"
dry "skip mime types"    "http://$TARGET" "-o /tmp/skipfish_$TARGET -c 'image/*' http://$TARGET"
dry "form handling"      "http://$TARGET" "-o /tmp/skipfish_$TARGET -I /tmp/skipfish_wordlist.wl http://$TARGET"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
