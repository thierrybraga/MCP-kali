#!/bin/bash
# ============================================================
# Pipeline de Testes Completa - Kali MCP Pentest Server
# ============================================================
# Executa todos os testes de integração e gera relatório
#
# Uso:
#   ./scripts/run-all-tests.sh [--url http://localhost:3000] [--target 127.0.0.1] [--skip-slow]
#
# Variáveis de ambiente:
#   MCP_BASE_URL   - URL base do servidor (default: http://localhost:3000)
#   TEST_TARGET    - IP/host para testes de execução real (default: 127.0.0.1)
#   TEST_WEB_URL   - URL para testes web (default: http://localhost:3000)
#   SKIP_SLOW      - Se "1", pula testes de execução real (apenas dry-run)
# ============================================================

set -uo pipefail

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Configuração ---
MCP_BASE_URL="${MCP_BASE_URL:-http://localhost:3000}"
TEST_TARGET="${TEST_TARGET:-127.0.0.1}"
TEST_WEB_URL="${TEST_WEB_URL:-http://localhost:3000}"
SKIP_SLOW="${SKIP_SLOW:-0}"
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/tests" && pwd)"
REPORT_DIR="${REPORT_DIR:-/tmp/mcp-test-results}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/test_report_$TIMESTAMP.txt"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) MCP_BASE_URL="$2"; shift 2 ;;
    --target) TEST_TARGET="$2"; shift 2 ;;
    --skip-slow) SKIP_SLOW="1"; shift ;;
    *) echo "Unknown arg: $1"; shift ;;
  esac
done

export MCP_BASE_URL TEST_TARGET TEST_WEB_URL

mkdir -p "$REPORT_DIR"

# --- Banner ---
echo -e "${BLUE}${BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║        Kali MCP Pentest Server - Test Pipeline              ║
║        Full Integration Test Suite                          ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo -e "${CYAN}Server:  ${BOLD}$MCP_BASE_URL${NC}"
echo -e "${CYAN}Target:  ${BOLD}$TEST_TARGET${NC}"
echo -e "${CYAN}WebURL:  ${BOLD}$TEST_WEB_URL${NC}"
echo -e "${CYAN}SkipSlow:${BOLD}$SKIP_SLOW${NC}"
echo -e "${CYAN}Report:  ${BOLD}$REPORT_FILE${NC}"
echo ""

# --- Verificar servidor ---
echo -e "${YELLOW}[*] Verificando conectividade com o servidor...${NC}"
if ! curl -sf "$MCP_BASE_URL/health" > /dev/null 2>&1; then
  echo -e "${RED}[ERRO] Servidor não acessível em $MCP_BASE_URL${NC}"
  echo "       Certifique-se que o servidor está rodando:"
  echo "       docker-compose up -d  (ou)  node server.js"
  exit 1
fi
echo -e "${GREEN}[OK] Servidor acessível${NC}"
echo ""

# --- Contadores globais ---
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
declare -a SUITE_RESULTS=()

# --- Função para executar uma suíte de testes ---
run_suite() {
  local name="$1"
  local script="$2"
  local skip="${3:-0}"

  ((TOTAL_SUITES++))

  if [ "$skip" = "1" ]; then
    echo -e "${YELLOW}[SKIP] Suite: $name${NC}"
    SUITE_RESULTS+=("SKIP: $name")
    return 0
  fi

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}Suite: $name${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  local output
  local start_time
  start_time=$(date +%s)

  if output=$(bash "$script" 2>&1); then
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "$output"
    echo -e "${GREEN}[SUITE PASSOU] $name (${duration}s)${NC}"
    ((PASSED_SUITES++))
    SUITE_RESULTS+=("PASS (${duration}s): $name")
    echo "$output" >> "$REPORT_FILE"
  else
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "$output"
    echo -e "${RED}[SUITE FALHOU] $name (${duration}s)${NC}"
    ((FAILED_SUITES++))
    SUITE_RESULTS+=("FAIL (${duration}s): $name")
    echo "$output" >> "$REPORT_FILE"
  fi
  echo ""
}

# ============================================================
# PIPELINE DE TESTES
# ============================================================

# Cabeçalho do relatório
{
  echo "=================================================="
  echo " Kali MCP Test Report - $TIMESTAMP"
  echo " Server: $MCP_BASE_URL"
  echo " Target: $TEST_TARGET"
  echo "=================================================="
  echo ""
} > "$REPORT_FILE"

# --- Grupo 1: Health & Conectividade ---
echo -e "${CYAN}${BOLD}═══ GRUPO 1: Health & Conectividade ═══${NC}"
run_suite "Health Check"            "$TESTS_DIR/test-health.sh"

# --- Grupo 2: Skills API ---
echo -e "${CYAN}${BOLD}═══ GRUPO 2: Skills API ═══${NC}"
run_suite "Skills Endpoints"        "$TESTS_DIR/test-skills.sh"

# --- Grupo 3: Reports & Artifacts ---
echo -e "${CYAN}${BOLD}═══ GRUPO 3: Reports & Tools List ═══${NC}"
run_suite "Reports & Artifacts"     "$TESTS_DIR/test-reports.sh"

# --- Grupo 4: Segurança ---
echo -e "${CYAN}${BOLD}═══ GRUPO 4: Controles de Segurança ═══${NC}"
run_suite "Security Controls"       "$TESTS_DIR/test-security.sh"

# --- Grupo 5: Ferramentas Genéricas (dry-run) ---
echo -e "${CYAN}${BOLD}═══ GRUPO 5: Ferramentas Genéricas (dry-run) ═══${NC}"
run_suite "Generic Tools Dry-Run"   "$TESTS_DIR/test-tools-generic.sh"

# --- Grupo 6: Pipeline ---
echo -e "${CYAN}${BOLD}═══ GRUPO 6: Pipeline Multi-Ferramenta ═══${NC}"
run_suite "Pipeline Tests"          "$TESTS_DIR/test-pipeline.sh"

# --- Grupo 7: Scanning (requer execução real) ---
echo -e "${CYAN}${BOLD}═══ GRUPO 7: Scanning Tools ═══${NC}"
run_suite "nmap Scanner"            "$TESTS_DIR/test-nmap.sh"      "$SKIP_SLOW"
run_suite "masscan Scanner"         "$TESTS_DIR/test-masscan.sh"   "$SKIP_SLOW"

# --- Grupo 8: Reconhecimento ---
echo -e "${CYAN}${BOLD}═══ GRUPO 8: Reconhecimento ═══${NC}"
run_suite "Recon (amass/subfinder)" "$TESTS_DIR/test-recon.sh"     "$SKIP_SLOW"

# --- Grupo 9: Web Tools ---
echo -e "${CYAN}${BOLD}═══ GRUPO 9: Web Application Tools ═══${NC}"
run_suite "Web Tools"               "$TESTS_DIR/test-web.sh"       "$SKIP_SLOW"

# --- Grupo 10: Brute Force ---
echo -e "${CYAN}${BOLD}═══ GRUPO 10: Brute Force ═══${NC}"
run_suite "Hydra Bruteforce"        "$TESTS_DIR/test-hydra.sh"     "$SKIP_SLOW"

# --- Grupo 11: Exploit ---
echo -e "${CYAN}${BOLD}═══ GRUPO 11: Exploitation ═══${NC}"
run_suite "Metasploit"              "$TESTS_DIR/test-metasploit.sh" "$SKIP_SLOW"

# --- Grupo 12: Password Cracking ---
echo -e "${CYAN}${BOLD}═══ GRUPO 12: Password Cracking ═══${NC}"
run_suite "Password Cracking"       "$TESTS_DIR/test-password-cracking.sh"

# --- Grupo 13: Wireless ---
echo -e "${CYAN}${BOLD}═══ GRUPO 13: Wireless Tools ═══${NC}"
run_suite "Wireless Tools"          "$TESTS_DIR/test-wireless.sh"

# --- Grupo 14: Exploitation Frameworks ---
echo -e "${CYAN}${BOLD}═══ GRUPO 14: Exploitation Frameworks ═══${NC}"
run_suite "Exploitation Frameworks" "$TESTS_DIR/test-exploitation.sh"

# --- Grupo 15: Sniffing & MITM ---
echo -e "${CYAN}${BOLD}═══ GRUPO 15: Sniffing & MITM ═══${NC}"
run_suite "Sniffing & MITM"         "$TESTS_DIR/test-sniffing.sh"

# --- Grupo 16: Post-Exploitation ---
echo -e "${CYAN}${BOLD}═══ GRUPO 16: Post-Exploitation ═══${NC}"
run_suite "Post-Exploitation"       "$TESTS_DIR/test-post-exploitation.sh"

# --- Grupo 17: Forensics & Reverse Engineering ---
echo -e "${CYAN}${BOLD}═══ GRUPO 17: Forensics & Reverse Engineering ═══${NC}"
run_suite "Forensics & RE"          "$TESTS_DIR/test-forensics.sh"

# --- Grupo 18: Active Directory & Network ---
echo -e "${CYAN}${BOLD}═══ GRUPO 18: Active Directory & Network ═══${NC}"
run_suite "AD & Network"            "$TESTS_DIR/test-ad-network.sh"

# ============================================================
# RELATÓRIO FINAL
# ============================================================
echo -e "${BLUE}${BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    RELATÓRIO FINAL                          ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BOLD}Suítes executadas: $TOTAL_SUITES${NC}"
echo -e "${GREEN}${BOLD}  Passaram: $PASSED_SUITES${NC}"
echo -e "${RED}${BOLD}  Falharam: $FAILED_SUITES${NC}"
echo ""
echo -e "${BOLD}Detalhes por suíte:${NC}"
for result in "${SUITE_RESULTS[@]}"; do
  if [[ "$result" == PASS* ]]; then
    echo -e "  ${GREEN}✓ $result${NC}"
  elif [[ "$result" == SKIP* ]]; then
    echo -e "  ${YELLOW}⊘ $result${NC}"
  else
    echo -e "  ${RED}✗ $result${NC}"
  fi
done

echo ""
echo -e "${CYAN}Relatório completo salvo em: ${BOLD}$REPORT_FILE${NC}"

{
  echo ""
  echo "=================================================="
  echo "RESULTADO FINAL"
  echo "  Total:   $TOTAL_SUITES suítes"
  echo "  Passou:  $PASSED_SUITES"
  echo "  Falhou:  $FAILED_SUITES"
  echo ""
  for result in "${SUITE_RESULTS[@]}"; do
    echo "  $result"
  done
  echo "=================================================="
} >> "$REPORT_FILE"

if [ "$FAILED_SUITES" -gt 0 ]; then
  echo -e "${RED}${BOLD}[RESULTADO] FALHOU ($FAILED_SUITES suítes com erro)${NC}"
  exit 1
else
  echo -e "${GREEN}${BOLD}[RESULTADO] TODOS OS TESTES PASSARAM${NC}"
  exit 0
fi
