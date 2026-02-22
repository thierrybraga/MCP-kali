#!/bin/bash
# Tool: sqlmap
# Skill: skills/sqlmap/SKILL.md
# Endpoint: POST /api/web/sqlmap
# Descrição: SQL injection automatizado com suporte a múltiplas técnicas e SGBDs
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

scan() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/web/sqlmap" \
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
    -d "{\"tool\":\"sqlmap\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== sqlmap ==="

echo "-- dry-run --"
dry "enum DBs"          "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 --dbs --batch"
dry "enum tables"       "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 -D testdb --tables --batch"
dry "dump table"        "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 -D testdb -T users --dump --batch"
dry "dump columns"      "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 -D testdb -T users -C username,password --dump --batch"
dry "POST attack"       "http://$TARGET/login.php"     "-u http://$TARGET/login.php --data 'user=test&pass=test' --dbs --batch"
dry "with cookie"       "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 --cookie 'PHPSESSID=abc' --dbs --batch"
dry "WAF evasion"       "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 --tamper=space2comment --random-agent --dbs --batch"
dry "time-based only"   "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 --technique=T --time-sec=3 --dbs --batch"
dry "is DBA check"      "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 --is-dba --current-user --batch"
dry "file read"         "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 --file-read /etc/passwd --batch"
dry "forms detection"   "http://$TARGET/login.php"     "-u http://$TARGET/login.php --forms --dbs --batch"
dry "proxy route"       "http://$TARGET/page.php?id=1" "-u http://$TARGET/page.php?id=1 --proxy http://127.0.0.1:8080 --dbs --batch"

echo ""
echo "-- endpoint /api/web/sqlmap --"
scan "basic SQLi test" "{\"url\":\"http://$TARGET/page.php?id=1\",\"options\":\"--dbs --batch --level 1\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
