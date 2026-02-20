---
name: "ffuf"
description: "Fuzzer web rápido e flexível. Use para descoberta de diretórios, parâmetros, subdomínios, virtual hosts e fuzzing de múltiplos pontos simultaneamente."
---

# ffuf

## Objetivo

- Descoberta de diretórios e arquivos ocultos em servidores web
- Fuzzing de parâmetros GET/POST para descoberta de endpoints
- Enumeração de subdomínios via fuzzing de vhost/Host header
- Fuzzing de múltiplos pontos com palavras-chave customizáveis (FUZZ, W1, W2)
- Filtro avançado de respostas por código HTTP, tamanho, palavras e linhas

## Endpoint

- /api/web/ffuf

## Requer target

- não

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                              |
|-----------|--------|-------------|--------------------------------------------------------|
| url       | string | sim         | URL com placeholder FUZZ (ex: https://site.com/FUZZ)  |
| wordlist  | string | sim         | Caminho para a wordlist                                |
| options   | string | não         | Flags adicionais do CLI ffuf                           |

## Flags Importantes

| Flag                    | Efeito                                                       |
|-------------------------|--------------------------------------------------------------|
| `-w wordlist`           | Wordlist (múltiplas: `-w w1:KEYWORD1 -w w2:KEYWORD2`)        |
| `-u URL`                | URL com placeholder FUZZ                                     |
| `-X POST`               | Método HTTP                                                  |
| `-d "data=FUZZ"`        | Body de POST com fuzzing                                     |
| `-H "Header: FUZZ"`     | Fuzzing de cabeçalhos                                        |
| `-e .php,.html,.txt`    | Extensões a testar                                           |
| `-fc 404,403`           | Filtrar por código de status                                 |
| `-fs N`                 | Filtrar por tamanho de resposta                              |
| `-fw N`                 | Filtrar por número de palavras                               |
| `-fl N`                 | Filtrar por número de linhas                                 |
| `-mc 200,301,302`       | Mostrar apenas estes códigos                                 |
| `-t N`                  | Threads (padrão: 40)                                         |
| `-rate N`               | Requisições por segundo                                      |
| `-o arquivo`            | Salvar output                                                |
| `-of json/html/csv`     | Formato de output                                            |
| `-recursion`            | Fuzzing recursivo em diretórios encontrados                  |
| `-v`                    | Verbose (mostra URL completa)                                |

## Wordlists Recomendadas

| Wordlist                                              | Uso                          |
|-------------------------------------------------------|------------------------------|
| `/usr/share/wordlists/dirb/common.txt`                | Descoberta geral rápida      |
| `/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt` | Descoberta detalhada |
| `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt` | Alta cobertura |
| `/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt` | Subdomínios |

## Exemplos

### Descoberta de diretórios básica
```json
{
  "url": "https://example.com/FUZZ",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "options": "-fc 404 -t 50"
}
```

### Fuzzing com extensões (PHP e HTML)
```json
{
  "url": "https://example.com/FUZZ",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "options": "-e .php,.html,.bak -fc 404 -t 30"
}
```

### Fuzzing de parâmetros GET
```json
{
  "url": "https://example.com/page.php?FUZZ=value",
  "wordlist": "/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt",
  "options": "-fc 404 -fs 1234"
}
```

### Fuzzing de subdomínios via Host header
```json
{
  "url": "https://FUZZ.example.com",
  "wordlist": "/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt",
  "options": "-H 'Host: FUZZ.example.com' -fs 0 -t 50"
}
```

### Fuzzing de POST body
```json
{
  "url": "https://example.com/login",
  "wordlist": "/usr/share/wordlists/rockyou.txt",
  "options": "-X POST -d 'username=admin&password=FUZZ' -fc 401 -t 20"
}
```

### Scan recursivo com output JSON
```json
{
  "url": "https://example.com/FUZZ",
  "wordlist": "/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt",
  "options": "-recursion -recursion-depth 3 -e .php -fc 404 -o /tmp/ffuf_results.json -of json"
}
```

## OPSEC

- Use `-rate` para limitar velocidade e evitar bloqueio por WAF/rate-limiting
- `-fs` é essencial para filtrar respostas de tamanho fixo (páginas de erro customizadas)
- Use `-H "User-Agent: ..."` para simular navegador e contornar bloqueios simples
- `-recursion` pode gerar muitas requisições — use com `-recursion-depth` controlado

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Com `-of json`, o arquivo de output lista cada resultado com URL, status, tamanho e palavras
