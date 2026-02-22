#!/bin/bash
# Test: Generic tool runner (/api/tools/run, /api/tools/dry-run, /api/tools/pipeline)
# Testa: whatweb, dalfox, commix, xsstrike, wafw00f, enum4linux, sslscan,
#        theharvester, dnsrecon, dmitry, assetfinder, gau, waybackurls,
#        paramspider, arjun, joomscan, cmsmap, droopescan, davtest,
#        arachni, skipfish, nosqlmap, strings, exiftool, binwalk, foremost
set -euo pipefail

BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
PASS=0; FAIL=0

pass() { echo "[PASS] $1"; ((PASS++)); }
fail() { echo "[FAIL] $1: $2"; ((FAIL++)); }

dry_run_check() {
  local tool="$1"
  local target="$2"
  local options="${3:-}"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"$tool\",\"target\":\"$target\",\"options\":\"$options\"}")
  echo "$R" | grep -q '"command"' \
    && pass "$tool: dry-run has command" \
    || fail "$tool: dry-run" "no command field: $R"
}

dry_run_no_target() {
  local tool="$1"
  local options="${2:-}"
  local R
  R=$(curl -sf -X POST "$BASE_URL/api/tools/dry-run" \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"$tool\",\"options\":\"$options\"}")
  echo "$R" | grep -q '"command"' \
    && pass "$tool (no-target): dry-run has command" \
    || fail "$tool (no-target): dry-run" "no command field: $R"
}

echo "=== Generic Tool Runner - /api/tools/* ==="

# --- Validação de ferramenta inválida ---
echo "-- validation --"
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/tools/run" \
  -H "Content-Type: application/json" -d '{}')
[ "$CODE" = "400" ] && pass "Missing tool returns 400" || fail "Missing tool" "got $CODE"

CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/tools/run" \
  -H "Content-Type: application/json" -d '{"tool":"nonexistent_tool_xyz"}')
[ "$CODE" = "400" ] && pass "Unknown tool returns 400" || fail "Unknown tool" "got $CODE"

# --- Ferramentas RECON ---
echo "-- recon tools dry-run --"
dry_run_check "whatweb"     "http://example.com"   "-a 1"
dry_run_check "wafw00f"     "http://example.com"   ""
dry_run_check "dmitry"      "example.com"          "-i"
dry_run_check "dnsrecon"    "example.com"          "-t std"
dry_run_check "sslscan"     "example.com:443"      ""
dry_run_check "enum4linux"  "192.168.1.100"        "-a"
dry_run_check "assetfinder" "example.com"          ""
dry_run_check "gau"         "example.com"          ""
dry_run_check "waybackurls" "example.com"          ""
dry_run_check "paramspider" "example.com"          ""
dry_run_check "arjun"       "http://example.com"   "-m GET"
dry_run_check "sublist3r"   "example.com"          "-t 10"
dry_run_check "cloudbrute"  "example.com"          ""
dry_run_check "massdns"     "targets.txt"          "-r resolvers.txt -t A"
dry_run_check "theharvester" "example.com"         "-b all -l 100"
dry_run_check "amap"        "192.168.1.100"        "80"
dry_run_check "lbd"         "example.com"          ""
dry_run_check "unicornscan" "192.168.1.100"        "-mT"
dry_run_check "smtp-user-enum" "192.168.1.100"     "-M VRFY -u admin"
dry_run_check "snmp-check"  "192.168.1.100"        ""
dry_run_check "ike-scan"    "192.168.1.100"        ""
dry_run_check "spiderfoot"  "example.com"          "-m all"
dry_run_no_target "recon-ng" ""
dry_run_no_target "sslstrip" ""

# --- Ferramentas WEB ---
echo "-- web tools dry-run --"
dry_run_check "xsstrike"    "http://example.com/search?q=test" ""
dry_run_check "commix"      "http://example.com/page?id=1"     "--batch"
dry_run_check "joomscan"    "http://joomla.example.com"        ""
dry_run_check "cmsmap"      "http://example.com"               ""
dry_run_check "droopescan"  "http://drupal.example.com"        "drupal"
dry_run_check "dalfox"      "http://example.com/search?q=test" "--silence"
dry_run_check "davtest"     "http://example.com"               ""
dry_run_check "skipfish"    "http://example.com"               "-o /tmp/skipfish"
dry_run_check "arachni"     "http://example.com"               ""
dry_run_check "nosqlmap"    "http://example.com"               ""
dry_run_check "httpx"       "example.com"                      "-status-code"
dry_run_no_target "brutespray" "-f nmap.xml"
dry_run_check "brutespray"  "192.168.1.0/24"                   "-f nmap.xml"

# --- Ferramentas PASSWORD ---
echo "-- password tools dry-run --"
dry_run_check "ncrack"      "192.168.1.100"        "-p ssh"
dry_run_check "cewl"        "http://example.com"   "-d 2 -m 8"
dry_run_no_target "crunch"  "8 8 abc123"
dry_run_no_target "ophcrack" ""

# --- Ferramentas WIRELESS ---
echo "-- wireless tools dry-run --"
dry_run_no_target "wifite"         "--wpa"
dry_run_no_target "bully"          "-b AA:BB:CC:DD:EE:FF wlan0"
dry_run_no_target "kismet"         "--no-ncurses"
dry_run_no_target "pixiewps"       ""
dry_run_no_target "fern-wifi-cracker" ""
dry_run_no_target "mdk4"           "wlan0 b"
dry_run_no_target "airgeddon"      ""
dry_run_no_target "wifi-pumpkin3"  ""

# --- Ferramentas EXPLOITATION ---
echo "-- exploitation tools dry-run --"
dry_run_no_target "routersploit"   ""
dry_run_no_target "set"            ""
dry_run_no_target "msfvenom"       "-p windows/meterpreter/reverse_tcp LHOST=127.0.0.1 LPORT=4444 -f exe"

# --- Ferramentas SNIFFING ---
echo "-- sniffing tools dry-run --"
dry_run_no_target "bettercap"      "-iface eth0"
dry_run_no_target "driftnet"       "-i eth0"
dry_run_no_target "mitmf"          "--interface eth0"
dry_run_no_target "yersinia"       "-G"

# --- Ferramentas POST-EXPLOITATION ---
echo "-- post-exploitation tools dry-run --"
dry_run_no_target "weevely"        "generate password /tmp/shell.php"
dry_run_no_target "lazagne"        "all"
dry_run_no_target "linux-exploit-suggester"  ""
dry_run_no_target "windows-exploit-suggester" "--database 2024-01-01-mssb.xls --systeminfo info.txt"

# --- Ferramentas FORENSICS ---
echo "-- forensics tools dry-run --"
dry_run_check "binwalk"     "/tmp/firmware.bin"    "-e"
dry_run_check "foremost"    "/tmp/disk.img"        "-o /tmp/foremost_output"
dry_run_check "radare2"     "/tmp/binary"          "-A"
dry_run_check "apktool"     "/tmp/app.apk"         "d"
dry_run_check "dex2jar"     "/tmp/app.dex"         ""
dry_run_check "strings"     "/tmp/binary"          "-a"
dry_run_check "exiftool"    "/tmp/image.jpg"       ""
dry_run_no_target "autopsy"  ""
dry_run_no_target "volatility" "-f /tmp/memory.dmp imageinfo"
dry_run_no_target "ghidra"   ""

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
