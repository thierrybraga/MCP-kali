#!/bin/bash
# Test: amass e subfinder endpoints
# Skills: skills/amass/SKILL.md, skills/subfinder/SKILL.md
# Endpoints: POST /api/recon/amass, POST /api/recon/subfinder
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== amass & subfinder - /api/recon/* ==="

# --- AMASS ---
# 1. Missing domain -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/recon/amass" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "amass: Missing domain returns 400" || fail "amass: Missing domain" "got $CODE"

# 2. Dry-run amass via tools
R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
  -H "Content-Type: application/json" \
  -d '{"tool":"assetfinder","target":"example.com","options":""}')
echo "$R" | grep -q '"command"' \
  && pass "amass/assetfinder dry-run has command" \
  || fail "assetfinder dry-run" "no command"

# 3. Amass com domain válido (passivo para ser rápido)
R=$(curl -sf -X POST "$BASE_URL/api/recon/amass" \
  -H "Content-Type: application/json" \
  -d '{"domain":"example.com","options":"-passive -timeout 30"}')
echo "$R" | grep -q '"tool":"amass"' \
  && pass "amass execution returns tool field" \
  || fail "amass execution" "unexpected response"

# --- SUBFINDER ---
# 4. Missing domain -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/recon/subfinder" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "subfinder: Missing domain returns 400" || fail "subfinder: Missing domain" "got $CODE"

# 5. Subfinder com domain válido
R=$(curl -sf -X POST "$BASE_URL/api/recon/subfinder" \
  -H "Content-Type: application/json" \
  -d '{"domain":"example.com","options":"-timeout 30"}')
echo "$R" | grep -q '"tool":"subfinder"' \
  && pass "subfinder execution returns tool field" \
  || fail "subfinder execution" "unexpected response"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
