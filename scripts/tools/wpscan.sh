#!/bin/bash
# Tool: wpscan
# Skill: skills/wpscan/SKILL.md
# Endpoint: POST /api/web/wpscan
# Descrição: Scanner de vulnerabilidades WordPress
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TARGET="${TEST_TARGET:-127.0.0.1}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

scan() {
  local desc="$1"; local body="$2"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/web/wpscan" \
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
    -d "{\"tool\":\"wpscan\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== wpscan ==="

echo "-- dry-run --"
dry "basic scan"         "http://$TARGET" "--url http://$TARGET --no-banner"
dry "enumerate users"    "http://$TARGET" "--url http://$TARGET -e u --no-banner"
dry "enumerate plugins"  "http://$TARGET" "--url http://$TARGET -e ap --no-banner"
dry "enumerate themes"   "http://$TARGET" "--url http://$TARGET -e at --no-banner"
dry "enumerate all"      "http://$TARGET" "--url http://$TARGET -e u,ap,at,tt,cb,dbe --no-banner"
dry "passive detection"  "http://$TARGET" "--url http://$TARGET --detection-mode passive --no-banner"
dry "aggressive detect"  "http://$TARGET" "--url http://$TARGET --detection-mode aggressive --no-banner"
dry "brute users"        "http://$TARGET" "--url http://$TARGET -U admin -P /usr/share/wordlists/rockyou.txt --no-banner"
dry "json output"        "http://$TARGET" "--url http://$TARGET -o /tmp/wpscan_$TARGET.json --format json --no-banner"
dry "with API token"     "http://$TARGET" "--url http://$TARGET --api-token TOKEN -e vp --no-banner"

echo ""
echo "-- endpoint /api/web/wpscan --"
scan "basic WP scan" "{\"url\":\"http://$TARGET\",\"options\":\"--no-banner\"}"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
