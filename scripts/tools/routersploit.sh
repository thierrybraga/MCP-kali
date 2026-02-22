#!/bin/bash
# Tool: routersploit
# Skill: skills/routersploit/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Framework de exploração de vulnerabilidades em roteadores e IoT
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
    -d "{\"tool\":\"routersploit\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== routersploit ==="

echo "-- dry-run --"
dry "autopwn scan"       "$TARGET" "-c 'use scanners/autopwn; set target $TARGET; run'"
dry "credentials scan"   "$TARGET" "-c 'use scanners/credentials/router_scan; set target $TARGET; run'"
dry "Cisco exploit"      "$TARGET" "-c 'use exploits/routers/cisco/cve_2019_1653; set target $TARGET; check'"
dry "D-Link exploit"     "$TARGET" "-c 'use exploits/routers/dlink/dir_300_600_rce; set target $TARGET; check'"
dry "list exploits"      ""        "-c 'show exploits'"
dry "list scanners"      ""        "-c 'show scanners'"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
