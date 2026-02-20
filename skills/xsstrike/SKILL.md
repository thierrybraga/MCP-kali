---
name: xsstrike
description: XSS scanner avançado com geração inteligente de payloads baseada em análise de contexto. Utiliza fuzzing, crawling e análise de respostas para criar payloads específicos para cada ponto de injeção. Suporta GET, POST, crawling de links, XSS cego e detecção fuzzer.
---

# xsstrike

## Objetivo
- Detectar vulnerabilidades XSS com payloads gerados inteligentemente por análise de contexto
- Analisar a estrutura da resposta para criar payloads que se encaixam no contexto HTML
- Realizar crawling automático para descobrir novos endpoints vulneráveis
- Testar parâmetros GET e POST incluindo formulários
- Detectar XSS cego (blind XSS) com callback de confirmação
- Executar fuzzing de parâmetros para descoberta de injeções latentes

## Endpoint
- /api/tools/run

## Requer target
- sim

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                                         |
|-----------|--------|-------------|-------------------------------------------------------------------|
| tool      | string | sim         | Deve ser exatamente xsstrike                                  |
| options   | string | sim         | Flags do CLI incluindo a URL alvo (-u) e opções adicionais        |

## Flags Importantes
| Flag                          | Efeito                                                                 |
|-------------------------------|------------------------------------------------------------------------|
| -u URL                        | URL alvo com parâmetros a testar                                       |
| --data param=valor        | Corpo da requisição POST para testar parâmetros no body               |
| --cookie name=value       | Cookie de autenticação ou sessão                                       |
| --headers H: V            | Headers HTTP customizados (ex: Authorization, X-Forwarded-For)        |
| --proxy http://host:porta     | Proxy para inspeção ou anonimização                                    |
| --timeout N                   | Timeout em segundos por requisição (padrão 10)                        |
| --threads N                   | Número de threads para execução paralela                               |
| --blind URL-callback          | URL de callback para detecção de XSS cego (blind XSS)                |
| --crawl                       | Rastreia links do alvo para descobrir novos pontos de injeção         |
| --fuzzer                      | Ativa modo fuzzer para descoberta de payloads não-convencionais       |
| --skip                        | Pula confirmação de vulnerabilidade (execução automática)             |
| --json                        | Saída no formato JSON estruturado                                      |
| --params                      | Detecta automaticamente parâmetros na URL                              |
| --seeds N                     | Número de seeds para geração de payloads (fuzzer)                     |

## Exemplos

### Caso 1: Teste básico em parâmetro GET com JSON


### Caso 2: Teste de formulário POST com cookie de sessão


### Caso 3: Crawling automático para descoberta de endpoints


### Caso 4: Blind XSS com callback de confirmação


### Caso 5: Fuzzer com proxy para análise detalhada


## OPSEC
- XStrike analisa o contexto (atributo HTML, tag, JavaScript) antes de gerar payloads: é mais preciso que scanners genéricos
- Use --threads moderado (2-5); valores altos podem triggerar rate limiting ou WAF
- --proxy é essencial para validar cada payload e confirmar reflexões antes de reportar
- --crawl expande a superfície de ataque mas gera mais tráfego; use com cuidado em alvos monitorados
- --blind é necessário para XSS armazenado onde a injeção executa em outra página/sessão
- --fuzzer encontra bypasses de filtro mas gera muito ruído; use apenas quando scanners normais falham
- --skip remove confirmações interativas, necessário para execução via API

## Saída
- success: booleano indicando execução sem erros críticos
- stdout: saída completa com análise de contexto e payloads testados
- stderr: erros de conectividade, timeout ou configuração
- report: vulnerabilidades confirmadas com payload e contexto de injeção
- artifacts: relatórios gerados em formato JSON se --json ativado
