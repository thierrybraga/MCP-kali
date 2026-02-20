---
name: "feroxbuster"
description: "Scanner de conteúdo web recursivo e rápido escrito em Rust. Use para descoberta de diretórios e arquivos com recursão automática e alta performance."
---

# feroxbuster

## Objetivo

- Descoberta recursiva automática de diretórios e arquivos web
- Alta performance (Rust) com controle fino de concorrência
- Filtros avançados por tamanho, palavras, linhas e regex
- Suporte a múltiplas extensões, cookies, cabeçalhos e proxy
- Modo de atualização ao vivo com cancelamento interativo

## Endpoint

- /api/web/feroxbuster

## Requer target

- não

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                  |
|-----------|--------|-------------|---------------------------------------------|
| url       | string | sim         | URL alvo                                   |
| options   | string | não         | Flags adicionais do CLI feroxbuster         |

## Flags Importantes

| Flag                      | Efeito                                                   |
|---------------------------|----------------------------------------------------------|
| `-u URL`                  | URL alvo                                                 |
| `-w wordlist`             | Wordlist                                                 |
| `-x php,html,txt`         | Extensões a testar                                       |
| `-t N`                    | Threads (padrão: 50)                                     |
| `--depth N`               | Profundidade máxima de recursão                          |
| `--no-recursion`          | Desativar recursão                                       |
| `-C 404,403`              | Filtrar códigos HTTP (blacklist)                         |
| `-s 200,301`              | Mostrar apenas estes códigos (whitelist)                 |
| `-S N`                    | Filtrar por tamanho de resposta                          |
| `-W N`                    | Filtrar por número de palavras                           |
| `-L N`                    | Filtrar por número de linhas                             |
| `--filter-regex "regex"`  | Filtrar por regex no body                                |
| `-H "Header: value"`      | Cabeçalho customizado                                    |
| `-b "cookie=value"`       | Cookie de sessão                                         |
| `--proxy http://...`      | Proxy HTTP/HTTPS/SOCKS                                   |
| `-o arquivo`              | Output em arquivo                                        |
| `--json`                  | Output em formato JSON                                   |
| `-q`                      | Quiet mode                                               |
| `--rate-limit N`          | Limite de requisições por segundo                        |
| `-k`                      | Ignorar erros de certificado TLS                         |
| `-r`                      | Seguir redirecionamentos                                 |
| `--random-agent`          | User-Agent aleatório                                     |

## Exemplos

### Scan básico com recursão
```json
{
  "url": "https://example.com",
  "options": "-w /usr/share/wordlists/dirb/common.txt -x php,html -C 404"
}
```

### Scan com controle de profundidade e extensões web
```json
{
  "url": "https://example.com",
  "options": "-w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,aspx,html,js --depth 3 -C 404,400 -t 30"
}
```

### Scan furtivo com rate limit e proxy
```json
{
  "url": "https://target.com",
  "options": "-w /usr/share/wordlists/dirb/common.txt --rate-limit 10 --proxy http://127.0.0.1:8080 --random-agent -C 404"
}
```

### Scan com sessão autenticada
```json
{
  "url": "https://app.example.com/dashboard",
  "options": "-w /usr/share/wordlists/dirb/common.txt -b 'session=eyJ...' -x php -C 404,302 --json -o /tmp/ferox_results.json"
}
```

### Scan sem recursão para mapeamento inicial
```json
{
  "url": "https://example.com",
  "options": "-w /usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt --no-recursion -C 404 -t 50 -q"
}
```

## OPSEC

- `--rate-limit` é essencial em ambientes com WAF ativo
- Use `--random-agent` para variar fingerprint de User-Agent
- `-t 50` (padrão) pode ser muito agressivo — use `-t 10-20` em produção
- Combine `-S` (filtro de tamanho) para eliminar páginas de erro genéricas
- Ideal para CTFs e pentests por ser o mais rápido dos scanners de conteúdo

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Com `--json`, cada resultado inclui url, status, content-length, words, lines e method
