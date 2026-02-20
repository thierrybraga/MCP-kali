---
name: commix
description: Command injection automatizado com suporte a múltiplas técnicas de exploração (classic, reverse shell, blind, time-based). Detecta e explora vulnerabilidades de injeção de comandos em parâmetros web GET e POST, extraindo informações do sistema operacional e podendo abrir shells interativos.
---

# commix

## Objetivo
- Detectar e explorar vulnerabilidades de OS command injection em aplicações web
- Testar parâmetros GET, POST, cookies e headers contra injeção de comandos
- Extrair informações do sistema: usuário, hostname, versão do OS, interfaces de rede
- Executar comandos arbitrários no servidor via injeção confirmada
- Abrir shell interativo ou reverse shell no sistema comprometido
- Ler e escrever arquivos no sistema de arquivos do servidor

## Endpoint
- /api/web/commix

## Requer target
- sim

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                                         |
|-----------|--------|-------------|-------------------------------------------------------------------|
| url       | string | sim         | URL alvo com parâmetros vulneráveis (ex: ?cmd=ls)                |
| options   | string | não         | Flags adicionais do CLI do commix                                 |

## Flags Importantes
| Flag                          | Efeito                                                                 |
|-------------------------------|------------------------------------------------------------------------|
| -u URL                        | URL alvo com parâmetros a testar                                       |
| --data param=valor        | Corpo da requisição POST                                               |
| --cookie name=value       | Cookie de autenticação ou sessão                                       |
| --headers H: V            | Headers HTTP customizados                                              |
| --proxy http://host:porta     | Roteia tráfego por proxy                                               |
| --level 1-3                   | Profundidade de teste (1=básico, 3=todos os vetores possíveis)        |
| --technique CRBE              | Técnicas: C=Classic, R=Reverse shell, B=Blind, E=Semi-blind (time)   |
| --os linux                    | Força tipo de OS alvo (linux ou windows)                               |
| --os windows                  | Força alvo Windows para usar comandos e sintaxe corretos              |
| --hostname                    | Extrai hostname do servidor                                             |
| --current-user                | Retorna o usuário que executa o processo web                           |
| --sys-info                    | Coleta informações completas do sistema (OS, kernel, arquitetura)     |
| --all                         | Executa todas as extrações de informação disponíveis                   |
| --os-cmd comando          | Executa um comando específico no OS via injeção                       |
| --os-shell                    | Abre shell interativo pseudo-TTY via injeção de comandos              |
| --file-read /etc/passwd       | Lê arquivo do servidor via command injection                           |
| --file-write local --file-dest /path | Escreve arquivo no servidor                                   |
| --batch                       | Modo não-interativo, responde automaticamente a prompts               |
| --random-agent                | Usa User-Agent aleatório                                               |
| --tamper=space2ifs            | Aplica tamper script para evasão de filtros                            |
| --ignore-code 403             | Ignora respostas com código HTTP específico                            |
| --time-sec N                  | Timeout para técnicas time-based/blind                                 |

## Exemplos

### Caso 1: Detecção básica com coleta de informações do sistema


### Caso 2: Injeção POST com cookie de sessão e execução de comando


### Caso 3: Leitura de arquivos sensíveis via injeção confirmada


### Caso 4: Técnica time-based blind com nível máximo de teste


### Caso 5: Alvo Windows com extração completa de informações


## OPSEC
- Comece com --level=1 e --technique=C (classic) para minimizar requisições ao alvo
- --batch é obrigatório para execução via API sem interação manual
- Técnica B (blind) gera muitas requisições para inferir saída bit a bit; use --time-sec alto em redes lentas
- --os linux/windows evita testes desnecessários para o OS errado, reduzindo ruído
- --proxy permite auditar cada payload enviado e confirmar a injeção manualmente
- Evite --os-shell em produção; prefira --os-cmd para execuções pontuais e controláveis
- --random-agent disfarça o User-Agent padrão do commix que pode ser detectado por WAF/IDS
- --file-read de /etc/passwd confirma injeção funcional sem causar dano ao sistema

## Saída
- success: booleano indicando execução sem erros críticos
- stdout: saída completa incluindo payloads testados e dados extraídos do sistema
- stderr: erros de conectividade ou técnica sem resultado
- report: resumo das vulnerabilidades confirmadas com técnica e parâmetro afetado
- artifacts: arquivos lidos do servidor e logs de execução
