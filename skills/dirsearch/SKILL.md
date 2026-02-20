---
name: "dirsearch"
description: "Scanner de caminhos web avançado. Use para descoberta de diretórios e arquivos com suporte a multi-threading, extensões, proxy e relatórios detalhados."
---

# dirsearch

## Objetivo

- Descoberta de diretórios, arquivos e caminhos ocultos em servidores web
- Suporte a múltiplas extensões simultâneas
- Scanning multi-threaded com controle de velocidade
- Geração de relatórios em múltiplos formatos
- Suporte a autenticação, cookies e cabeçalhos customizados

## Endpoint

- /api/web/dirsearch

## Requer target

- não

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                       |
|-----------|--------|-------------|--------------------------------------------------|
| url       | string | sim         | URL base do alvo                                |
| options   | string | não         | Flags adicionais do CLI dirsearch               |

## Flags Importantes

| Flag                        | Efeito                                                 |
|-----------------------------|--------------------------------------------------------|
| `-u URL`                    | URL alvo                                               |
| `-e php,html,txt`           | Extensões a testar                                     |
| `-w wordlist`               | Wordlist customizada                                   |
| `-t N`                      | Threads (padrão: 25)                                   |
| `-r`                        | Scanning recursivo                                     |
| `--recursion-depth N`       | Profundidade máxima de recursão                        |
| `-x 404,403`                | Excluir códigos HTTP                                   |
| `--include-status 200,301`  | Incluir apenas estes códigos                           |
| `--proxy http://...`        | Usar proxy HTTP                                        |
| `-H "Header: value"`        | Cabeçalho customizado                                  |
| `--cookie "name=value"`     | Cookie de sessão                                       |
| `--auth user:pass`          | Autenticação HTTP básica                               |
| `-o arquivo`                | Salvar output                                          |
| `--format plain/json/csv`   | Formato de output                                      |
| `--delay N`                 | Delay em ms entre requisições                          |
| `--random-agent`            | User-Agent aleatório a cada requisição                 |
| `-q`                        | Quiet mode                                             |

## Exemplos

### Scan básico com extensões comuns
```json
{
  "url": "https://example.com",
  "options": "-e php,html,txt,bak -t 25"
}
```

### Scan recursivo completo
```json
{
  "url": "https://example.com",
  "options": "-e php,html,js,json -r --recursion-depth 3 -t 20 -x 404,429 -o /tmp/dirsearch.txt"
}
```

### Scan com autenticação e proxy
```json
{
  "url": "https://internal.app.com",
  "options": "-e php,aspx -t 10 --proxy http://127.0.0.1:8080 --auth admin:secret123"
}
```

### Scan furtivo com delay e user-agent aleatório
```json
{
  "url": "https://target.com",
  "options": "-e php,html -t 5 --delay 500 --random-agent -x 404,403,429"
}
```

### Scan com wordlist customizada e output JSON
```json
{
  "url": "https://example.com",
  "options": "-w /usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt -e php -t 30 --format json -o /tmp/dirsearch_results.json"
}
```

## OPSEC

- Use `--random-agent` para variar User-Agent e evitar bloqueios simples
- `--delay` ajuda a contornar rate limiting de WAFs
- `-x 403` pode omitir recursos protegidos — avalie incluir e registrar
- Prefira `-t 10-20` em ambientes de produção para evitar impacto

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Com `--format json`, cada resultado inclui URL, status, tamanho e redirecionamento
