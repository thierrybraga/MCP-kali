#!/bin/bash
# Tool: ike-scan
# Skill: skills/ike-scan/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Descoberta e fingerprinting de gateways VPN IPsec/IKE
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"ike-scan\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== ike-scan ==="

echo "-- dry-run --"
dry "IKEv1 scan"            "$TARGET" "$TARGET"
dry "aggressive mode"       "$TARGET" "--aggressive $TARGET"
dry "transform check"       "$TARGET" "--trans=5,2,1,2 $TARGET"
dry "PSK crack mode"        "$TARGET" "--pskcrack=/tmp/pskhash.txt $TARGET"
dry "show backoff"          "$TARGET" "--showbackoff $TARGET"
dry "multi target"          "10.0.0.0/24" "10.0.0.0/24"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
