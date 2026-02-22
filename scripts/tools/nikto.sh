#!/bin/bash
# Tool: nikto
# Skill: skills/nikto/SKILL.md
# Endpoint: POST /api/web/nikto
# Descrição: Scanner de vulnerabilidades de servidor web
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

scan() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/web/nikto" \
    -H "Content-Type: application/json" \
    -d "$body") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local options="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"nikto\",\"target\":\"$TARGET\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== nikto ==="

echo "-- dry-run --"
dry "basic HTTP"            "-h $TARGET -p 80 -nointeractive"
dry "HTTPS scan"            "-h $TARGET -p 443 -ssl -nointeractive"
dry "custom port"           "-h $TARGET -p 8080 -nointeractive"
dry "XSS+injection tuning"  "-h $TARGET -Tuning 34 -nointeractive"
dry "file tuning"           "-h $TARGET -Tuning 1 -nointeractive"
dry "output HTML"           "-h $TARGET -Format html -output /tmp/nikto_$TARGET.html -nointeractive"
dry "output CSV"            "-h $TARGET -Format csv -output /tmp/nikto_$TARGET.csv -nointeractive"
dry "basic auth"            "-h $TARGET -id admin:password -nointeractive"
dry "with timeout"          "-h $TARGET -timeout 5 -maxtime 120 -nointeractive"

echo ""
echo "-- endpoint /api/web/nikto --"
scan "basic HTTP scan"      "{\"host\":\"$TARGET\",\"port\":80,\"ssl\":false}"
scan "with options"         "{\"host\":\"$TARGET\",\"port\":80,\"ssl\":false,\"options\":\"-timeout 5 -maxtime 60 -nointeractive\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
