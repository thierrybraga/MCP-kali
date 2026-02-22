#!/bin/bash
# Test: Skills API endpoints
# Endpoints: GET /api/skills/list, GET /api/skills/:tool
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

echo "=== Skills API - /api/skills/* ==="

# 1. Listar todas as skills
R=$(curl -sf "$BASE_URL/api/skills/list")
echo "$R" | grep -q '"skills"' \
  && pass "GET /api/skills/list returns skills array" \
  || fail "GET /api/skills/list" "no skills field"

COUNT=$(echo "$R" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('skills',[])))")
[ "$COUNT" -gt 0 ] \
  && pass "Skills list has $COUNT skills" \
  || fail "Skills count" "expected > 0, got $COUNT"

# 2. Buscar skill específica
SKILLS=(nmap nikto masscan sqlmap wpscan gobuster ffuf nuclei dalfox commix subfinder amass
        xsstrike wafw00f whatweb sslscan enum4linux dnsrecon theharvester hydra
        pentest-basico pentest-web pentest-recon pentest-report
        volatility binwalk exiftool strings radare2)

for skill in "${SKILLS[@]}"; do
  R=$(curl -sf "$BASE_URL/api/skills/$skill" 2>/dev/null)
  if echo "$R" | grep -q '"content"'; then
    pass "GET /api/skills/$skill has content"
  else
    # Skill pode não existir (ok se não houver arquivo)
    echo "[INFO] Skill '$skill' not found (SKILL.md may be missing)"
    ((FAIL++)) || true
  fi
done

# 3. Skill inválida -> 404
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/skills/nonexistent_tool_xyz")
[ "$CODE" = "404" ] && pass "Unknown skill returns 404" || fail "Unknown skill" "got $CODE"

# 4. Path traversal protection
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/skills/../server")
[ "$CODE" = "404" ] && pass "Path traversal blocked (404)" || fail "Path traversal" "got $CODE"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
