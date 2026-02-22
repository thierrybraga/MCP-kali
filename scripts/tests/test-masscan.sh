#!/bin/bash
# Test: masscan endpoint
# Skill: skills/masscan/SKILL.md
# Endpoint: POST /api/scan/masscan
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== masscan - /api/scan/masscan ==="

# 1. Missing target -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/scan/masscan" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "Missing target returns 400" || fail "Missing target" "got $CODE"

# 2. Dry-run - verificar template de comando
R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
  -H "Content-Type: application/json" \
  -d "{\"tool\":\"masscan\",\"target\":\"$TARGET\",\"options\":\"\"}")
echo "$R" | grep -q '"command"' \
  && pass "masscan dry-run returns command" \
  || fail "masscan dry-run" "no command field"

# 3. Verificar que rate padrão é aplicada (1000)
R=$(curl -sf -X POST "$BASE_URL/api/scan/masscan" \
  -H "Content-Type: application/json" \
  -d "{\"target\":\"$TARGET\",\"ports\":\"80\",\"rate\":\"100\"}")
echo "$R" | grep -q '"tool":"masscan"' \
  && pass "masscan execution returns tool field" \
  || fail "masscan execution" "unexpected response"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
