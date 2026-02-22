#!/bin/bash
# Tool: amap
# Skill: skills/amap/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Identificação de aplicações em portas não-padrão
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
    -d "{\"tool\":\"amap\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== amap ==="

echo "-- dry-run --"
dry "banner grab port 80"   "$TARGET" "-b $TARGET 80"
dry "banner grab multiple"  "$TARGET" "-b $TARGET 80 443 8080"
dry "app identification"    "$TARGET" "-A $TARGET 80 443"
dry "UDP identification"    "$TARGET" "-u $TARGET 53 161"
dry "verbose mode"          "$TARGET" "-bv $TARGET 22 80 443"
dry "output file"           "$TARGET" "-b -o /tmp/amap_results.txt $TARGET 80 443"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
