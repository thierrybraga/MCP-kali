#!/bin/bash
# Tool: nosqlmap
# Skill: skills/nosqlmap/SKILL.md
# Endpoint: POST /api/web/nosqlmap
# Descrição: Detecção e exploração de injeção NoSQL (MongoDB, CouchDB, Redis)
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

scan() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/web/nosqlmap" \
    -H "Content-Type: application/json" \
    -d "$body") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -qE '"success":(true|false)' \
    && pass "$desc" \
    || fail "$desc" "unexpected: $R"
}

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"nosqlmap\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== nosqlmap ==="

echo "-- dry-run --"
dry "GET injection"      "http://$TARGET" "--attack 1 --uri http://$TARGET/api/users?id=test"
dry "POST injection"     "http://$TARGET" "--attack 1 --uri http://$TARGET/api/login --httpMethod POST --postData 'username=admin&password=test'"
dry "MongoDB direct"     "$TARGET"        "--attack 2 --mongoHost $TARGET --mongoPort 27017"
dry "dump collections"   "$TARGET"        "--attack 2 --mongoHost $TARGET --mongoDump"
dry "auth bypass"        "http://$TARGET" "--attack 1 --uri http://$TARGET/login --httpMethod POST --postData 'username=admin&password=test'"

echo ""
echo "-- endpoint /api/web/nosqlmap --"
scan "GET injection" "{\"url\":\"http://$TARGET/api/users?id=test\",\"options\":\"--attack 1\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
