#!/bin/bash
# Tool: ldapdomaindump
# Skill: skills/ldapdomaindump/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Dump completo de objetos AD via LDAP — users, groups, computers, policies
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
    -d "{\"tool\":\"ldapdomaindump\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== ldapdomaindump ==="

echo "-- dry-run --"
dry "NTLM auth dump"     "$TARGET" "-u 'CORP\\admin' -p Password123 -o /tmp/ldd/ $TARGET"
dry "UPN auth"           "$TARGET" "-u admin@corp.local -p Password123 -o /tmp/ldd/ $TARGET"
dry "LDAPS (port 636)"   "$TARGET" "-u 'CORP\\admin' -p Password123 -l -o /tmp/ldd/ $TARGET"
dry "Simple auth"        "$TARGET" "-u admin -p Password123 -at SIMPLE -o /tmp/ldd/ $TARGET"
dry "No HTML output"     "$TARGET" "-u 'CORP\\admin' -p Password123 --no-html -o /tmp/ldd/ $TARGET"
dry "No JSON output"     "$TARGET" "-u 'CORP\\admin' -p Password123 --no-json -o /tmp/ldd/ $TARGET"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
