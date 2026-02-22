#!/bin/bash
# Test: Reports e Artifacts API
# Endpoints: GET /api/reports, GET /api/artifacts, GET /api/tools/list
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== Reports & Artifacts & Tools List ==="

# --- /api/tools/list ---
R=$(curl -sf "$BASE_URL/api/tools/list")
echo "$R" | grep -q '"tools"' \
  && pass "GET /api/tools/list returns tools array" \
  || fail "GET /api/tools/list" "no tools field"

COUNT=$(echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('tools',[])))")
[ "$COUNT" -gt 10 ] \
  && pass "Tools list has $COUNT tools (expected >10)" \
  || fail "Tools count" "expected >10, got $COUNT"

echo "$R" | python3 -c "
import sys, json
d = json.load(sys.stdin)
tools = d.get('tools', [])
missing_fields = [t['name'] for t in tools if 'category' not in t or 'description' not in t]
if missing_fields:
    print('Missing fields in:', missing_fields[:5])
    exit(1)
" && pass "All tools have category and description" || fail "Tools fields" "some missing fields"

# --- /api/reports ---
R=$(curl -sf "$BASE_URL/api/reports")
echo "$R" | grep -q '"reports"' \
  && pass "GET /api/reports returns reports array" \
  || fail "GET /api/reports" "no reports field"

# --- /api/artifacts ---
R=$(curl -sf "$BASE_URL/api/artifacts")
echo "$R" | grep -q '"artifacts"' \
  && pass "GET /api/artifacts returns artifacts array" \
  || fail "GET /api/artifacts" "no artifacts field"

# --- /api/artifacts com filtros ---
R=$(curl -sf "$BASE_URL/api/artifacts?tool=nmap")
echo "$R" | grep -q '"artifacts"' \
  && pass "GET /api/artifacts?tool=nmap works" \
  || fail "GET /api/artifacts?tool=nmap" "unexpected response"

R=$(curl -sf "$BASE_URL/api/artifacts?type=report")
echo "$R" | grep -q '"artifacts"' \
  && pass "GET /api/artifacts?type=report works" \
  || fail "GET /api/artifacts?type=report" "unexpected response"

# --- /api/reports/summary/:filename (arquivo inexistente -> 404) ---
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/reports/summary/nonexistent_file.txt")
[ "$CODE" = "404" ] \
  && pass "GET /api/reports/summary/nonexistent -> 404" \
  || fail "Report summary 404" "got $CODE"

# --- /api/reports/:filename (arquivo inexistente -> 404) ---
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/reports/nonexistent_file.txt")
[ "$CODE" = "404" ] \
  && pass "GET /api/reports/nonexistent -> 404" \
  || fail "Report content 404" "got $CODE"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
