#!/bin/bash
# Tool: enum4linux
# Skill: skills/enum4linux/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Enumeração de informações Windows/Samba via protocolo SMB
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
    -d "{\"tool\":\"enum4linux\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== enum4linux ==="

echo "-- dry-run --"
dry "all enumeration"    "$TARGET" "-a $TARGET"
dry "users only"         "$TARGET" "-U $TARGET"
dry "groups only"        "$TARGET" "-G $TARGET"
dry "shares only"        "$TARGET" "-S $TARGET"
dry "password policy"    "$TARGET" "-P $TARGET"
dry "OS info"            "$TARGET" "-o $TARGET"
dry "users+groups+shares" "$TARGET" "-U -G -S $TARGET"
dry "with credentials"   "$TARGET" "-u admin -p Password123 -a $TARGET"
dry "RID brute"          "$TARGET" "-r $TARGET"
dry "verbose"            "$TARGET" "-v -a $TARGET"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
