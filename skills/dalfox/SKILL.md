---
name: dalfox
description: XSS scanner moderno e rápido escrito em Go. Detecta reflexões e execuções de XSS em parâmetros GET/POST, cookies e headers. Suporta mineração de parâmetros, payloads remotos, DOM XSS profundo e geração de PoC automatizada. Ideal para pipelines de bug bounty e testes de regressão contínuos.
---

# dalfox

## Objetivo
- Detectar vulnerabilidades Cross-Site Scripting (XSS) de forma automatizada e eficiente
- Testar parâmetros GET, POST, cookies e headers HTTP contra injeções XSS
- Minerar parâmetros ocultos automaticamente (parameter mining)
- Detectar DOM XSS em profundidade via análise de JavaScript
- Integrar payloads remotos atualizados (PayloadsAllTheThings, etc.)
- Gerar PoCs reproduzíveis em formato JSON ou texto

## Endpoint
- /api/web/dalfox

## Requer target
- sim

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                                  |
|-----------|--------|-------------|-------------------------------------------------------------|
| url       | string | sim         | URL alvo completa com parâmetros (ex: ?search=test)        |
| options   | string | não         | Flags adicionais do CLI do dalfox concatenadas              |

## Flags Importantes
| Flag                              | Efeito                                                               |
|-----------------------------------|----------------------------------------------------------------------|
| -p param                          | Testa especificamente o parâmetro informado                          |
| --cookie name=value           | Envia cookie para autenticação ou manutenção de sessão               |
| --header Nome: Valor          | Adiciona header HTTP customizado                                      |
| --proxy http://127.0.0.1:8080     | Roteia tráfego por proxy (Burp, ZAP, mitmproxy)                     |
| --output /tmp/resultado.txt       | Salva saída em arquivo                                                |
| --format json                     | Formata saída como JSON estruturado                                   |
| --silence                         | Suprime output visual, exibe apenas vulnerabilidades encontradas      |
| --mining-dict                     | Ativa mineração de parâmetros via dicionário                         |
| --mining-dom                      | Ativa mineração de parâmetros via análise do DOM                    |
| --deep-domxss                     | Análise profunda de DOM XSS (mais lento, mais abrangente)           |
| --remote-payloads                 | Busca payloads atualizados de repositórios remotos                   |
| --custom-payload /path/file.txt   | Usa arquivo de payloads customizados                                  |
| -w /path/wordlist.txt             | Wordlist de parâmetros para mineração                                |
| --only-custom-payload             | Usa exclusivamente os payloads do arquivo --custom-payload           |
| --ignore-return 302,404           | Ignora respostas com esses status codes                               |
| --timeout N                       | Timeout em segundos por requisição                                    |
| --delay N                         | Delay em milissegundos entre requisições                              |
| --worker N                        | Número de workers concorrentes                                        |
| --skip-bav                        | Pula verificação de análise de valor básico                          |
| --mass                            | Modo para múltiplos alvos via stdin (pipe)                           |
| --follow-redirects                | Segue redirecionamentos HTTP                                          |
| --har /tmp/session.har            | Importa arquivo HAR para replay de requisições                       |
| --blind URL-callback              | Testa XSS cego com URL de callback para confirmar execução           |

## Exemplos

### Caso 1: Varredura básica em parâmetro de busca


### Caso 2: Teste autenticado com cookie e parâmetro específico


### Caso 3: Mineração de parâmetros ocultos com DOM XSS


### Caso 4: XSS cego com callback e payloads remotos


### Caso 5: Payloads customizados com proxy para análise


## OPSEC
- Use --silence para minimizar output e --delay para reduzir frequência de requisições
- --worker padrão é eficiente; aumente apenas em alvos que tolerem alta carga
- --proxy permite inspecionar e validar cada payload enviado antes de confirmar achados
- Em ambientes com WAF, combine --custom-payload com payloads ofuscados
- --blind é essencial para XSS armazenado onde o reflexo não aparece na resposta imediata
- Use --ignore-return 302 para evitar falsos positivos em páginas de redirecionamento
- --format json facilita integração com pipelines automatizados e relatórios

## Saída
- success: booleano indicando execução sem erros críticos
- stdout: saída completa incluindo parâmetros testados e vulnerabilidades encontradas
- stderr: erros de conectividade ou configuração
- report: resumo das injeções confirmadas com PoC
- artifacts: arquivos de saída gerados (--output)
