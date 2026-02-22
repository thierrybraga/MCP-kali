#!/bin/bash
# Test: Health & Root endpoints
# Tool: Server health check
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1"; ((FAIL++)); }

echo "=== Health & Root ==="

# GET /health
R=$(curl -sf "$BASE_URL/health") && echo "$R" | grep -q '"status":"healthy"' \
  && pass "GET /health returns healthy" \
  || fail "GET /health"

# GET /
R=$(curl -sf "$BASE_URL/") && echo "$R" | grep -q '"name"' \
  && pass "GET / returns server info" \
  || fail "GET /"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
