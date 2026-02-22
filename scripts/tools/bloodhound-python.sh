#!/bin/bash
# Tool: bloodhound-python
# Skill: skills/bloodhound/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Coleta de dados AD para análise de caminhos de ataque no BloodHound
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"bloodhound-python\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== bloodhound-python ==="

echo "-- dry-run --"
dry "All collection"    "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c All --zip"
dry "DC only collect"   "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c DCOnly --zip"
dry "ACL collection"    "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c ACL --zip"
dry "Trusts only"       "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c Trusts --zip"
dry "with nameserver"   "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c All --zip -ns $TARGET"
dry "output directory"  "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c All --zip -o /tmp/bh_output"
dry "with kerberos"     "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c All --zip -k"
dry "stealth mode"      "-d CORP.LOCAL -u admin -p Password123 --dc $TARGET -c DCOnly --zip"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
