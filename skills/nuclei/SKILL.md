---
name: "nuclei"
description: "Scanner de vulnerabilidades baseado em templates. Use para detecção automatizada e escalável de CVEs, misconfigurations, exposições e vulnerabilidades web."
---

# nuclei

## Objetivo

- Varredura automatizada baseada em templates YAML customizáveis
- Detecção de CVEs conhecidos em aplicações e infraestrutura
- Identificação de configurações incorretas (misconfigs)
- Detecção de exposições sensíveis (credenciais, chaves API, painéis admin)
- Teste de tecnologias: cloud, DNS, network, SSL, HTTP

## Endpoint

- /api/web/nuclei

## Requer target

- sim

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                      |
|-----------|--------|-------------|------------------------------------------------|
| target    | string | sim         | URL ou IP alvo (aceita arquivo de targets)     |
| options   | string | não         | Flags adicionais do CLI nuclei                 |

## Flags Importantes

| Flag                      | Efeito                                                        |
|---------------------------|---------------------------------------------------------------|
| `-t templates/`           | Diretório de templates a usar                                 |
| `-tags cve,rce`           | Filtrar por tags                                              |
| `-severity critical,high` | Filtrar por severidade                                        |
| `-rl N`                   | Rate limit (requisições por segundo)                          |
| `-c N`                    | Concorrência (padrão 25)                                      |
| `-timeout N`              | Timeout por requisição                                        |
| `-o arquivo`              | Salvar output em arquivo                                      |
| `-json`                   | Output em formato JSON                                        |
| `-silent`                 | Somente resultados, sem banner                                |
| `-resume`                 | Retomar scan interrompido                                     |
| `-es info`                | Excluir resultados de severidade info                         |
| `-H "Header: value"`      | Cabeçalho HTTP customizado                                    |
| `-proxy http://...`       | Usar proxy (ex: Burp Suite)                                   |
| `-update-templates`       | Atualizar templates do repositório oficial                    |

## Exemplos

### Scan padrão com todos os templates
```json
{
  "target": "https://example.com",
  "options": "-silent"
}
```

### Scan focado em CVEs críticos e altos
```json
{
  "target": "https://target.com",
  "options": "-tags cve -severity critical,high -json -o /tmp/nuclei_cves.json"
}
```

### Scan de configurações incorretas em cloud/infra
```json
{
  "target": "https://app.example.com",
  "options": "-tags misconfig,exposure -rl 50 -silent"
}
```

### Scan com proxy (Burp Suite) para análise manual paralela
```json
{
  "target": "https://example.com",
  "options": "-proxy http://127.0.0.1:8080 -tags xss,sqli"
}
```

### Múltiplos alvos de arquivo
```json
{
  "target": "/tmp/targets.txt",
  "options": "-severity high,critical -c 10 -rl 30 -o /tmp/results.json -json"
}
```

## OPSEC

- Use `-rl` para limitar requisições e evitar bloqueios por WAF
- Prefira `-tags` específicos para reduzir volume de tráfego
- Sempre execute `-update-templates` antes de scans em engajamentos reais
- Em ambientes sensíveis, combine com `-proxy` para logar e revisar cada requisição

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Com `-json`, cada linha do stdout é um finding individual em JSON
- Campos por finding: `templateID`, `severity`, `matched-at`, `info`
