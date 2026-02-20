---
name: nosqlmap
description: NoSQL injection automatizado focado em bancos MongoDB, CouchDB e Redis. Detecta e explora vulnerabilidades de injeção em aplicações que usam SGBDs NoSQL, suportando técnicas timing-based, boolean-based, error-based e JavaScript injection. Permite extração de coleções, documentos e bypass de autenticação.
---

# nosqlmap

## Objetivo
- Detectar e explorar vulnerabilidades de NoSQL injection em aplicações web
- Atacar bancos de dados MongoDB, CouchDB e Redis via injeção em parâmetros HTTP
- Realizar bypass de autenticação explorando operadores NoSQL (\, \, \)
- Extrair nomes de bancos, coleções e documentos via injeção confirmada
- Executar JavaScript injection no contexto do servidor MongoDB (eval)
- Suportar técnicas timing-based, boolean-based e error-based para injeção cega

## Endpoint
- /api/web/nosqlmap

## Requer target
- sim

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                                         |
|-----------|--------|-------------|-------------------------------------------------------------------|
| url       | string | sim         | URL alvo com parâmetros vulneráveis                               |
| options   | string | não         | Flags adicionais do CLI do nosqlmap                               |

## Flags Importantes
| Flag                     | Efeito                                                                      |
|--------------------------|-----------------------------------------------------------------------------|
| -u URL                   | URL alvo com parâmetros a testar                                             |
| --attack 1               | Técnica timing-based (detecta via tempo de resposta)                        |
| --attack 2               | Técnica boolean-based (detecta via diferença de respostas true/false)       |
| --attack 3               | Técnica error-based (detecta via mensagens de erro do SGBD)                 |
| --attack 4               | JavaScript injection (eval no contexto do servidor MongoDB)                 |
| --httpMethod GET         | Força método HTTP GET nas requisições                                        |
| --httpMethod POST        | Força método HTTP POST nas requisições                                       |
| --postData param=val | Dados do corpo da requisição POST a testar                                  |
| --dbPort 27017           | Porta do banco de dados alvo (padrão MongoDB: 27017)                        |
| --dbName nome_db         | Nome do banco de dados alvo para enumeração                                 |
| --colName nome_colecao   | Nome da coleção alvo para extração de documentos                            |
| --findone                | Extrai apenas o primeiro documento (menos ruído, confirmação rápida)        |
| -v                       | Modo verbose: exibe detalhes de cada requisição e resposta                  |
| --host hostname          | Hostname ou IP do servidor MongoDB para ataque direto                       |
| --shellPort porta        | Porta para conexão direta com shell MongoDB                                 |

## Exemplos

### Caso 1: Detecção com técnica boolean-based em parâmetro GET


### Caso 2: Injeção em POST de login para bypass de autenticação


### Caso 3: JavaScript injection para extração de dados (MongoDB eval)


### Caso 4: Enumeração de coleção específica via timing-based


### Caso 5: Ataque error-based em endpoint POST com verbose


## OPSEC
- Inicie com --attack 2 (boolean-based): é o mais confiável e menos intrusivo
- --attack 1 (timing-based) pode gerar muitas requisições lentas; use --attack 2 primeiro
- --attack 4 (JS injection) é o mais poderoso mas também o mais intrusivo; use apenas quando confirmada a vulnerabilidade
- --findone limita a extração ao primeiro documento, reduzindo volume de tráfego
- -v verbose é útil para debug mas gera muito output; desative em execuções automatizadas
- NoSQL injection com operadores (\, \) pode bypassar autenticação sem deixar rastros óbvios em logs de aplicação
- Confirme o SGBD alvo (MongoDB vs CouchDB vs Redis) antes de escolher a técnica de ataque
- Em MongoDB com autenticação fraca, tente --attack 2 no endpoint de login antes de técnicas mais invasivas

## Saída
- success: booleano indicando execução sem erros críticos
- stdout: saída completa incluindo técnica usada, parâmetros testados e dados extraídos
- stderr: erros de conectividade ou ausência de vulnerabilidade detectada
- report: resumo das injeções confirmadas com técnica, parâmetro e dados obtidos
- artifacts: documentos extraídos e logs de execução
