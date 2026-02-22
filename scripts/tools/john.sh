#!/bin/bash
# Tool: john
# Skill: skills/john/SKILL.md
# Endpoint: POST /api/tools/dry-run | /api/tools/run
# Descrição: John the Ripper — crack de hashes com dicionário, regras e força bruta
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry() {
  local desc="$1"; local target="$2"; local options="$3"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"john\",\"target\":\"$target\",\"options\":\"$options\"}") || { fail "$desc" "curl error"; return; }
  echo "$R" | grep -q '"command"' \
    && pass "$desc" \
    || fail "$desc" "no command: $R"
}

echo "=== john ==="

echo "-- dry-run --"
dry "wordlist attack"     "/tmp/hashes.txt"  "--wordlist=/usr/share/wordlists/rockyou.txt /tmp/hashes.txt"
dry "wordlist + rules"    "/tmp/hashes.txt"  "--wordlist=/usr/share/wordlists/rockyou.txt --rules /tmp/hashes.txt"
dry "auto detect format"  "/tmp/hashes.txt"  "--wordlist=/usr/share/wordlists/rockyou.txt /tmp/hashes.txt"
dry "MD5 format"          "/tmp/md5.txt"     "--format=md5crypt --wordlist=/usr/share/wordlists/rockyou.txt /tmp/md5.txt"
dry "NTLM hashes"         "/tmp/ntlm.txt"    "--format=NT --wordlist=/usr/share/wordlists/rockyou.txt /tmp/ntlm.txt"
dry "SHA256 hashes"       "/tmp/sha256.txt"  "--format=sha256crypt --wordlist=/usr/share/wordlists/rockyou.txt /tmp/sha256.txt"
dry "bcrypt hashes"       "/tmp/bcrypt.txt"  "--format=bcrypt --wordlist=/usr/share/wordlists/rockyou.txt /tmp/bcrypt.txt"
dry "incremental mode"    "/tmp/hashes.txt"  "--incremental /tmp/hashes.txt"
dry "single crack"        "/tmp/shadow.txt"  "--single /tmp/shadow.txt"
dry "show cracked"        "/tmp/hashes.txt"  "--show /tmp/hashes.txt"
dry "ssh2john"            "/tmp/id_rsa"      "--show /tmp/id_rsa.hash"
dry "zip2john"            "/tmp/archive.zip" "--show /tmp/archive.hash"
dry "restore session"     ""                 "--restore"
dry "mask attack"         "/tmp/hashes.txt"  "--mask=?u?l?l?l?d?d /tmp/hashes.txt"

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
