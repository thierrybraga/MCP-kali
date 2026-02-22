#!/bin/bash
# Test: hydra endpoint
# Skill: skills/hydra/SKILL.md (via /api/tools/run)
# Endpoint: POST /api/bruteforce/hydra
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== hydra - /api/bruteforce/hydra ==="

# 1. Missing target -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/bruteforce/hydra" \
  -H "Content-Type: application/json" -d '{"service":"ssh"}')
[ "$CODE" = "400" ] && pass "Missing target returns 400" || fail "Missing target" "got $CODE"

# 2. Missing service -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/bruteforce/hydra" \
  -H "Content-Type: application/json" -d '{"target":"192.168.1.1"}')
[ "$CODE" = "400" ] && pass "Missing service returns 400" || fail "Missing service" "got $CODE"

# 3. Verificar estrutura de resposta com target válido
R=$(curl -sf -X POST "$BASE_URL/api/bruteforce/hydra" \
  -H "Content-Type: application/json" \
  -d '{"target":"127.0.0.1","service":"ssh","username":"test","password":"test","options":"-t 1"}')
echo "$R" | grep -q '"tool":"hydra"' \
  && pass "hydra execution returns tool field" \
  || fail "hydra execution" "unexpected response"
echo "$R" | grep -q '"command"' \
  && pass "hydra execution has command field" \
  || fail "hydra command" "no command field"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
