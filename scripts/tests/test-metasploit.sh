#!/bin/bash
# Test: Metasploit endpoint
# Skill: skills/msfconsole/SKILL.md
# Endpoint: POST /api/exploit/msfconsole
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== Metasploit - /api/exploit/msfconsole ==="

# 1. Missing commands -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/exploit/msfconsole" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "Missing commands returns 400" || fail "Missing commands" "got $CODE"

# 2. Commands não é array -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/exploit/msfconsole" \
  -H "Content-Type: application/json" -d '{"commands":"exit"}')
[ "$CODE" = "400" ] && pass "Non-array commands returns 400" || fail "Non-array commands" "got $CODE"

# 3. Execução simples (version + exit)
R=$(curl -sf -X POST "$BASE_URL/api/exploit/msfconsole" \
  -H "Content-Type: application/json" \
  -d '{"commands":["version","exit"]}')
echo "$R" | grep -q '"tool":"msfconsole"' \
  && pass "msfconsole execution returns tool field" \
  || fail "msfconsole execution" "unexpected response"
echo "$R" | grep -q '"command"' \
  && pass "msfconsole has command field" \
  || fail "msfconsole command" "no command field"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
