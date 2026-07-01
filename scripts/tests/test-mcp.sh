#!/bin/bash
# Test: MCP JSON-RPC protocol endpoint
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

json_check() {
  local desc="$1"
  local expr="$2"
  local input="$3"
  echo "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if ($expr) else 1)" \
    && pass "$desc" \
    || fail "$desc" "unexpected JSON: $input"
}

echo "=== MCP JSON-RPC Endpoint ==="

R=$(curl -sf -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}')
json_check "initialize returns protocol and tool capability" \
  "'result' in d and d['result'].get('protocolVersion') == '2025-06-18' and 'tools' in d['result'].get('capabilities', {})" "$R"

CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}')
[ "$CODE" = "202" ] && pass "initialized notification returns 202" || fail "initialized notification" "got $CODE"

R=$(curl -sf -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}')
json_check "tools/list returns MCP tools with schemas" \
  "any(t.get('name') == 'whatweb' and 'inputSchema' in t for t in d.get('result', {}).get('tools', []))" "$R"

R=$(curl -sf -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"whatweb","arguments":{"target":"http://example.com","options":"-a 1","dryRun":true}}}')
json_check "tools/call dryRun returns structured command" \
  "'result' in d and d['result'].get('structuredContent', {}).get('command')" "$R"

R=$(curl -sf -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"nonexistent_tool_xyz","arguments":{}}}')
json_check "unknown tool returns JSON-RPC error" \
  "d.get('error', {}).get('code') == -32602" "$R"

R=$(curl -sf -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":5,"method":"resources/list","params":{}}')
json_check "resources/list exposes skill resources" \
  "any(r.get('uri') == 'skill://nmap' for r in d.get('result', {}).get('resources', []))" "$R"

R=$(curl -sf -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":6,"method":"resources/read","params":{"uri":"skill://nmap"}}')
json_check "resources/read returns skill content" \
  "'contents' in d.get('result', {}) and d['result']['contents'][0].get('mimeType') == 'text/markdown'" "$R"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
