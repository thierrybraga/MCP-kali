#!/bin/bash
# Test: Pipeline multi-ferramenta
# Endpoint: POST /api/tools/pipeline
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== Pipeline - /api/tools/pipeline ==="

# 1. Empty steps -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/tools/pipeline" \
  -H "Content-Type: application/json" -d '{"steps":[]}')
[ "$CODE" = "400" ] && pass "Empty steps returns 400" || fail "Empty steps" "got $CODE"

# 2. Missing steps -> 400
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/tools/pipeline" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "Missing steps returns 400" || fail "Missing steps" "got $CODE"

# 3. Pipeline dry-run com ferramentas válidas
R=$(curl -sf -X POST "$BASE_URL/api/tools/pipeline" \
  -H "Content-Type: application/json" \
  -d '{
    "steps": [
      {"tool":"assetfinder","target":"example.com","options":"","dryRun":true},
      {"tool":"whatweb","target":"http://example.com","options":"-a 1","dryRun":true},
      {"tool":"wafw00f","target":"http://example.com","options":"","dryRun":true}
    ]
  }')
echo "$R" | grep -q '"results"' \
  && pass "Pipeline dry-run returns results array" \
  || fail "Pipeline dry-run" "no results array"
COUNT=$(echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('results',[])))")
[ "$COUNT" = "3" ] \
  && pass "Pipeline returns 3 results" \
  || fail "Pipeline count" "expected 3, got $COUNT"

# 4. Pipeline com ferramenta inválida deve lidar graciosamente
R=$(curl -sf -X POST "$BASE_URL/api/tools/pipeline" \
  -H "Content-Type: application/json" \
  -d '{
    "steps": [
      {"tool":"nonexistent_xyz","target":"example.com","dryRun":true},
      {"tool":"whatweb","target":"http://example.com","dryRun":true}
    ]
  }')
echo "$R" | grep -q '"results"' \
  && pass "Pipeline with invalid tool still returns results" \
  || fail "Pipeline invalid tool" "no results"
echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('results',[]); exit(0 if any(not x.get('success') for x in r) else 1)" \
  && pass "Pipeline invalid tool has failure result" \
  || fail "Pipeline invalid tool" "all results succeeded"

# 5. Pipeline recon completo (dry-run)
R=$(curl -sf -X POST "$BASE_URL/api/tools/pipeline" \
  -H "Content-Type: application/json" \
  -d '{
    "steps": [
      {"tool":"assetfinder","target":"example.com","options":"","dryRun":true},
      {"tool":"waybackurls","target":"example.com","options":"","dryRun":true},
      {"tool":"gau","target":"example.com","options":"","dryRun":true},
      {"tool":"subfinder","target":"example.com","options":"","dryRun":true},
      {"tool":"httpx","target":"example.com","options":"-status-code","dryRun":true}
    ]
  }')
COUNT=$(echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('results',[])))")
[ "$COUNT" = "5" ] \
  && pass "Full recon pipeline returns 5 results" \
  || fail "Full recon pipeline" "expected 5, got $COUNT"

# 6. Verificar que pipeline retorna timestamp
echo "$R" | grep -q '"timestamp"' \
  && pass "Pipeline has timestamp" \
  || fail "Pipeline timestamp" "no timestamp"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
