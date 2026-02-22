#!/bin/bash
# Test: Web application testing tools
# Skills: nikto, dirb, gobuster, ffuf, feroxbuster, dirsearch, httpx, nuclei, wpscan, sqlmap
# Endpoints: POST /api/web/*
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET_URL="${TEST_WEB_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== Web Tools - /api/web/* ==="

# --- NIKTO ---
echo "-- nikto --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/nikto" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "nikto: Missing host returns 400" || fail "nikto: Missing host" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/nikto" \
  -H "Content-Type: application/json" \
  -d '{"host":"localhost","port":3000,"ssl":false}')
echo "$R" | grep -q '"tool":"nikto"' \
  && pass "nikto execution returns tool field" \
  || fail "nikto execution" "unexpected response"

# --- DIRB ---
echo "-- dirb --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/dirb" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "dirb: Missing url returns 400" || fail "dirb: Missing url" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/dirb" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$TARGET_URL\"}")
echo "$R" | grep -q '"tool":"dirb"' \
  && pass "dirb execution returns tool field" \
  || fail "dirb execution" "unexpected response"

# --- GOBUSTER ---
echo "-- gobuster --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/gobuster" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "gobuster: Missing url returns 400" || fail "gobuster: Missing url" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/gobuster" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$TARGET_URL\",\"mode\":\"dir\"}")
echo "$R" | grep -q '"tool":"gobuster"' \
  && pass "gobuster execution returns tool field" \
  || fail "gobuster execution" "unexpected response"

# --- FFUF ---
echo "-- ffuf --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/ffuf" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "ffuf: Missing url returns 400" || fail "ffuf: Missing url" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/ffuf" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$TARGET_URL/FUZZ\"}")
echo "$R" | grep -q '"tool":"ffuf"' \
  && pass "ffuf execution returns tool field" \
  || fail "ffuf execution" "unexpected response"

# --- FEROXBUSTER ---
echo "-- feroxbuster --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/feroxbuster" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "feroxbuster: Missing url returns 400" || fail "feroxbuster: Missing url" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/feroxbuster" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$TARGET_URL\",\"options\":\"--depth 1 --no-recursion\"}")
echo "$R" | grep -q '"tool":"feroxbuster"' \
  && pass "feroxbuster execution returns tool field" \
  || fail "feroxbuster execution" "unexpected response"

# --- DIRSEARCH ---
echo "-- dirsearch --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/dirsearch" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "dirsearch: Missing url returns 400" || fail "dirsearch: Missing url" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/dirsearch" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$TARGET_URL\"}")
echo "$R" | grep -q '"tool":"dirsearch"' \
  && pass "dirsearch execution returns tool field" \
  || fail "dirsearch execution" "unexpected response"

# --- HTTPX ---
echo "-- httpx --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/httpx" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "httpx: Missing target returns 400" || fail "httpx: Missing target" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/httpx" \
  -H "Content-Type: application/json" \
  -d '{"target":"localhost:3000","options":"-status-code"}')
echo "$R" | grep -q '"tool":"httpx"' \
  && pass "httpx execution returns tool field" \
  || fail "httpx execution" "unexpected response"

# --- NUCLEI ---
echo "-- nuclei --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/nuclei" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "nuclei: Missing target returns 400" || fail "nuclei: Missing target" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/web/nuclei" \
  -H "Content-Type: application/json" \
  -d "{\"target\":\"$TARGET_URL\",\"options\":\"-t exposures/ -silent\"}")
echo "$R" | grep -q '"tool":"nuclei"' \
  && pass "nuclei execution returns tool field" \
  || fail "nuclei execution" "unexpected response"

# --- SQLMAP (dry-run via tools) ---
echo "-- sqlmap --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/sqlmap" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "sqlmap: Missing url returns 400" || fail "sqlmap: Missing url" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
  -H "Content-Type: application/json" \
  -d '{"tool":"commix","target":"http://example.com/page?id=1","options":"--batch"}')
echo "$R" | grep -q '"command"' \
  && pass "sqlmap/commix dry-run has command" \
  || fail "sqlmap dry-run" "no command"

# --- WPSCAN (dry-run) ---
echo "-- wpscan --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/web/wpscan" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "wpscan: Missing url returns 400" || fail "wpscan: Missing url" "got $CODE"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
