#!/bin/bash
# Test: nmap endpoint
# Skill: skills/nmap/SKILL.md
# Endpoint: POST /api/scan/nmap
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== nmap - /api/scan/nmap ==="

# 1. Missing target -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/scan/nmap" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "Missing target returns 400" || fail "Missing target" "got $CODE"

# 2. Dry-run via /api/tools/dry-run para verificar comando gerado
R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
  -H "Content-Type: application/json" \
  -d '{"tool":"nmap","target":"127.0.0.1","options":"-sn"}')
echo "$R" | grep -q '"command"' \
  && pass "nmap dry-run returns command" \
  || fail "nmap dry-run" "no command field"

# 3. Execução real - scan básico (host discovery, rápido)
R=$(curl -sf -X POST "$BASE_URL/api/scan/nmap" \
  -H "Content-Type: application/json" \
  -d "{\"target\":\"$TARGET\",\"options\":\"-sn -T4\"}")
echo "$R" | grep -q '"tool":"nmap"' \
  && pass "nmap execution returns tool field" \
  || fail "nmap execution" "unexpected response"
echo "$R" | grep -q '"stdout"' \
  && pass "nmap execution has stdout" \
  || fail "nmap stdout" "no stdout"

# 4. Blocked token test
R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
  -H "Content-Type: application/json" \
  -d '{"tool":"nmap","target":"127.0.0.1","options":"-sn && echo pwned"}')
echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if not d.get('success') else 1)" \
  && pass "nmap blocked token rejected" \
  || fail "nmap blocked token" "should be rejected"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
