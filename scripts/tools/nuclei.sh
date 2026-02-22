#!/bin/bash
# Tool: nuclei
# Skill: skills/nuclei/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: Scanner de vulnerabilidades baseado em templates YAML
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
    -d "{\"tool\":\"nuclei\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== nuclei ==="

echo "-- dry-run --"
dry "single target"      "http://$TARGET" "-u http://$TARGET -silent"
dry "critical+high only" "http://$TARGET" "-u http://$TARGET -severity critical,high -silent"
dry "CVE templates"      "http://$TARGET" "-u http://$TARGET -t /root/nuclei-templates/cves/ -silent"
dry "tech detect"        "http://$TARGET" "-u http://$TARGET -t /root/nuclei-templates/technologies/ -silent"
dry "misconfiguration"   "http://$TARGET" "-u http://$TARGET -t /root/nuclei-templates/misconfiguration/ -silent"
dry "target list"        ""               "-l /tmp/urls.txt -severity medium,high,critical -silent"
dry "json output"        "http://$TARGET" "-u http://$TARGET -json-export /tmp/nuclei_$TARGET.json -silent"
dry "rate limit"         "http://$TARGET" "-u http://$TARGET -rl 50 -silent"
dry "with proxy"         "http://$TARGET" "-u http://$TARGET -proxy http://127.0.0.1:8080 -silent"
dry "update templates"   ""               "-update-templates"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
