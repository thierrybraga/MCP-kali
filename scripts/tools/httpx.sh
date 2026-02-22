#!/bin/bash
# Tool: httpx
# Skill: skills/httpx/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Probing HTTP/HTTPS em massa com detecção de tech, status codes e metadados
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
DOMAIN="${TEST_DOMAIN:-example.com}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"httpx\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== httpx ==="

echo "-- dry-run --"
dry "probe single"       "$TARGET" "-u http://$TARGET -silent"
dry "probe list"         ""        "-l /tmp/subdomains.txt -silent -status-code"
dry "with tech detect"   "$TARGET" "-u http://$TARGET -tech-detect -silent"
dry "with title"         "$TARGET" "-u http://$TARGET -title -silent"
dry "with content-type"  "$TARGET" "-u http://$TARGET -content-type -silent"
dry "json output"        "$TARGET" "-u http://$TARGET -json -silent"
dry "probe ports"        "$TARGET" "-l /tmp/hosts.txt -ports 80,443,8080,8443 -silent"
dry "follow redirects"   "$TARGET" "-u http://$TARGET -follow-redirects -silent"
dry "match status"       ""        "-l /tmp/urls.txt -mc 200,301,302 -silent"
dry "filter status"      ""        "-l /tmp/urls.txt -fc 404,403 -silent"
dry "rate limited"       ""        "-l /tmp/urls.txt -rate-limit 50 -silent"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
