---
name: sqlmap
description: SQL injection automatizado com suporte a múltiplas técnicas (blind, error-based, time-based, union, stacked). Detecta e explora vulnerabilidades SQLi em parâmetros GET, POST, cookies, headers e formulários. Permite extração de banco de dados, dump de tabelas, leitura de arquivos e obtenção de shell.
---

# sqlmap

## Objetivo
- Detectar e explorar automaticamente vulnerabilidades de SQL injection
- Enumerar bancos de dados, tabelas, colunas e extrair dados
- Suportar múltiplos SGBDs: MySQL, PostgreSQL, MSSQL, Oracle, SQLite, MariaDB
- Realizar ataques via GET, POST, cookies, headers HTTP e arquivos de requisição bruta
- Escalar privilégios: leitura/escrita de arquivos, execução de comandos no OS
- Integrar com tor, proxies e técnicas de evasão via tamper scripts

## Endpoint
- /api/web/sqlmap

## Requer target
- não (url é passada dentro de options ou como parâmetro url)

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                              |
|-----------|--------|-------------|--------------------------------------------------------|
| url       | string | sim         | URL alvo com parâmetros vulneráveis (ex: ?id=1)       |
| options   | string | não         | Flags adicionais do CLI do sqlmap concatenadas         |

## Flags Importantes
| Flag                          | Efeito                                                              |
|-------------------------------|---------------------------------------------------------------------|
| --batch                       | Responde automaticamente a todas as prompts (modo não-interativo)   |
| --dbs                         | Enumera todos os bancos de dados disponíveis                        |
| --tables                      | Lista tabelas do banco selecionado                                  |
| --dump                        | Extrai todos os dados das tabelas encontradas                       |
| -D nome_db                    | Seleciona banco de dados específico                                 |
| -T nome_tabela                | Seleciona tabela específica                                         |
| -C col1,col2                  | Limita dump a colunas específicas                                   |
| --risk=1-3                    | Nível de risco dos payloads (1=baixo, 3=agressivo)                 |
| --level=1-5                   | Profundidade de teste (1=básico, 5=todos os vetores)               |
| --dbms=mysql                  | Força SGBD específico (mysql, postgresql, mssql, oracle, sqlite)   |
| --technique=BEUSTQ            | Técnicas: B=Boolean, E=Error, U=Union, S=Stacked, T=Time, Q=Inline|
| --forms                       | Detecta e testa formulários HTML automaticamente                    |
| --data body=value         | Corpo da requisição POST                                            |
| --cookie session=abc      | Envia cookie de autenticação                                        |
| --headers X-Token: val    | Adiciona headers customizados                                       |
| --proxy http://127.0.0.1:8080 | Roteia tráfego por proxy (Burp, OWASP ZAP)                         |
| --tor                         | Usa rede Tor para anonimização                                      |
| --threads N                   | Número de threads concorrentes (padrão 1)                          |
| --time-sec N                  | Tempo de espera para técnicas time-based (padrão 5)                |
| --os-shell                    | Tenta abrir shell interativo no sistema operacional                 |
| --os-cmd comando          | Executa comando único no OS via injeção                             |
| --file-read /etc/passwd       | Lê arquivo do servidor via SQLi                                     |
| --file-write local --file-dest /path | Escreve arquivo no servidor                               |
| --passwords                   | Tenta extrair hashes de senhas do SGBD                              |
| --current-user                | Retorna o usuário atual do SGBD                                     |
| --is-dba                      | Verifica se o usuário atual tem privilégios de DBA                  |
| -r arquivo.txt                | Usa arquivo de requisição HTTP bruta (capturada do Burp)           |
| --tamper=space2comment        | Aplica tamper script para evasão de WAF                             |
| --random-agent                | Usa User-Agent aleatório a cada requisição                          |
| --flush-session               | Limpa cache de sessão anterior do sqlmap                            |
| --output-dir=/tmp/out         | Salva resultados em diretório específico                            |
| --smart                       | Heurística inteligente antes de testes completos                    |

## Exemplos

### Caso 1: Detecção básica com enumeração de bancos


### Caso 2: Dump de tabela específica autenticado com cookie


### Caso 3: Ataque POST com dados de formulário e evasão de WAF


### Caso 4: Requisição bruta do Burp Suite, verificando privilégios e tentando shell


### Caso 5: Extração time-based furtiva via proxy


## OPSEC
- Use --risk=1 e --level=1 em testes iniciais para reduzir ruído nos logs do alvo
- --threads=1 (padrão) gera menos tráfego anômalo; evite valores altos em alvos monitorados
- --tamper scripts (space2comment, between, randomcase) ajudam a evadir WAF/IDS
- --random-agent substitui o User-Agent padrão do sqlmap, que é facilmente bloqueado
- Use --proxy para inspecionar tráfego gerado antes de enviar ao alvo
- Evite --os-shell em ambientes de produção; prefira --os-cmd para comandos pontuais
- --tor adiciona anonimização mas aumenta latência; ajuste --time-sec se usar time-based
- Limpe sessões antigas com --flush-session ao re-testar o mesmo alvo

## Saída
- success: booleano indicando se o comando foi executado sem erros
- stdout: saída completa do sqlmap incluindo bancos/tabelas/dados encontrados
- stderr: erros e avisos da execução
- report: resumo estruturado das vulnerabilidades encontradas
- artifacts: arquivos gerados (dumps CSV, logs, sessão sqlmap)
