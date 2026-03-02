# Scripts e Testes

Este diretório contém scripts de automação e a suíte de testes de integração para o Kali MCP Server.

## Estrutura

- `run-all-tests.sh`: **Script principal** para execução de toda a suíte de testes.
- `tests/`: Diretório contendo scripts de teste individuais para cada categoria de ferramenta.

## Como Executar os Testes

Para rodar todos os testes:

```bash
./run-all-tests.sh
```

Para rodar testes rápidos (apenas dry-run, sem scan real):

```bash
SKIP_SLOW=1 ./run-all-tests.sh
```

## Adicionando Novos Testes

1. Crie um novo script em `tests/` (ex: `test-nova-ferramenta.sh`).
2. Siga o padrão dos scripts existentes:
   - Use `set -euo pipefail`.
   - Defina `BASE_URL`.
   - Implemente funções `pass()` e `fail()`.
   - Teste endpoints com `curl`.
3. Adicione a chamada ao novo script em `run-all-tests.sh`.

## Testes Disponíveis

| Script | Descrição |
|--------|-----------|
| `test-health.sh` | Verifica saúde do servidor (`/health`) |
| `test-skills.sh` | Verifica listagem e detalhes de skills |
| `test-tools-generic.sh` | Testa dry-run para dezenas de ferramentas |
| `test-nmap.sh` | Testa execução real e dry-run do Nmap |
| `test-web.sh` | Testa ferramentas web (nikto, gobuster, sqlmap) |
| `test-pipeline.sh` | Testa o endpoint de pipeline multi-estágio |
| `test_gateway_integration.py` | Teste de integração com Gateway ZeroClaw (Python) |

## Manutenção

- Scripts `auto_bruteforce.sh` e `full_recon.sh` foram removidos em favor das ferramentas integradas via API.
- Utilize sempre a API MCP para interagir com as ferramentas, garantindo log, auditoria e controle de acesso.
