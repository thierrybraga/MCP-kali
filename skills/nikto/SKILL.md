---
name: "nikto"
description: "Scanner de vulnerabilidades de servidor web. Use para detectar configurações inseguras, arquivos expostos, versões desatualizadas e problemas de cabeçalhos HTTP."
---

# nikto

## Objetivo

- Detectar configurações inseguras em servidores web
- Identificar arquivos e diretórios perigosos expostos
- Verificar cabeçalhos HTTP de segurança ausentes
- Detectar versões desatualizadas de software web
- Listar plugins, frameworks e tecnologias identificadas

## Endpoint

- /api/web/nikto

## Requer target

- não

## Parâmetros

| Parâmetro | Tipo    | Obrigatório | Descrição                           |
|-----------|---------|-------------|-------------------------------------|
| host      | string  | sim         | IP ou hostname do alvo              |
| port      | integer | não         | Porta (padrão: 80 ou 443 com SSL)   |
| ssl       | boolean | não         | Usar HTTPS (padrão: false)          |
| options   | string  | não         | Flags adicionais do CLI             |

## Flags Importantes

| Flag                  | Efeito                                                |
|-----------------------|-------------------------------------------------------|
| `-ssl`                | Forçar uso de HTTPS                                   |
| `-port N`             | Porta não-padrão                                      |
| `-Tuning X`           | Tipos de teste (1=arquivo, 2=cgi, 3=XSS, 4=injeção…) |
| `-output arquivo`     | Salvar resultado em arquivo                           |
| `-Format html/csv`    | Formato de saída                                      |
| `-nointeractive`      | Rodar sem prompts                                     |
| `-timeout N`          | Timeout por requisição em segundos                    |
| `-useragent "UA"`     | Definir User-Agent customizado                        |
| `-id user:pass`       | Autenticação HTTP básica                              |
| `-vhost hostname`     | Virtual host alvo                                     |
| `-maxtime N`          | Tempo máximo total do scan (segundos)                 |

## Exemplos

### Scan básico HTTP
```json
{
  "host": "192.168.1.100",
  "port": 80,
  "ssl": false
}
```

### Scan HTTPS com output HTML
```json
{
  "host": "example.com",
  "port": 443,
  "ssl": true,
  "options": "-Format html -output /tmp/nikto_report.html"
}
```

### Scan focado em XSS e injeção
```json
{
  "host": "192.168.1.50",
  "port": 8080,
  "ssl": false,
  "options": "-Tuning 34"
}
```

### Scan com autenticação básica
```json
{
  "host": "intranet.corp.local",
  "port": 80,
  "ssl": false,
  "options": "-id admin:password123"
}
```

### Scan silencioso com timeout reduzido
```json
{
  "host": "10.10.10.50",
  "port": 443,
  "ssl": true,
  "options": "-timeout 10 -maxtime 300 -nointeractive"
}
```

## OPSEC

- Nikto é **barulhento** — gera muitas requisições e é facilmente detectado por WAFs/IDS
- Use `-maxtime` para limitar duração e reduzir exposição
- Combine com wafw00f antes para verificar presença de WAF
- Não execute em produção sem autorização explícita

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- O campo `report` lista vulnerabilidades encontradas por categoria
- Guarde o output para evidências do pentest
