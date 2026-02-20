---
name: "gobuster"
description: "Ferramenta de brute force para diretórios, DNS e virtual hosts. Use para descoberta de caminhos web, subdomínios e buckets de cloud."
---

# gobuster

## Objetivo

- Brute force de diretórios e arquivos em servidores web (modo `dir`)
- Enumeração de subdomínios via DNS (modo `dns`)
- Descoberta de virtual hosts (modo `vhost`)
- Enumeração de buckets S3/GCS/Azure (modo `s3`, `gcs`, `az`)
- Fuzzing de caminhos com extensões múltiplas

## Endpoint

- /api/web/gobuster

## Requer target

- não

## Parâmetros

| Parâmetro  | Tipo   | Obrigatório | Descrição                                     |
|------------|--------|-------------|-----------------------------------------------|
| url        | string | sim*        | URL alvo (modos dir/vhost)                    |
| wordlist   | string | sim         | Caminho para a wordlist                       |
| mode       | string | sim         | Modo: dir, dns, vhost, s3, fuzz               |
| extensions | string | não         | Extensões separadas por vírgula (modo dir)    |
| options    | string | não         | Flags adicionais do CLI                       |

## Modos Disponíveis

| Modo    | Uso                                                   |
|---------|-------------------------------------------------------|
| `dir`   | Brute force de diretórios/arquivos em URL             |
| `dns`   | Enumeração de subdomínios via DNS                     |
| `vhost` | Descoberta de virtual hosts via cabeçalho Host        |
| `s3`    | Enumeração de buckets S3                              |
| `fuzz`  | Fuzzing genérico com placeholder FUZZ                 |

## Flags Importantes

| Flag                   | Efeito                                                |
|------------------------|-------------------------------------------------------|
| `-u URL`               | URL alvo                                              |
| `-w wordlist`          | Wordlist                                              |
| `-x php,html,txt`      | Extensões a testar (modo dir)                         |
| `-t N`                 | Threads (padrão: 10)                                  |
| `-s "200,301,302"`     | Códigos de status aceitos                             |
| `-b "404,403"`         | Códigos de status negados (blacklist)                 |
| `-r`                   | Seguir redirecionamentos                              |
| `-k`                   | Ignorar erros de certificado SSL                      |
| `-c "cookie=value"`    | Enviar cookie de sessão                               |
| `-H "Header: value"`   | Cabeçalhos customizados                               |
| `-o arquivo`           | Salvar output em arquivo                              |
| `-q`                   | Quiet mode (somente resultados)                       |
| `-d domínio`           | Domínio alvo (modo dns)                               |
| `--delay N`            | Delay em ms entre requisições                         |

## Exemplos

### Brute force de diretórios básico
```json
{
  "url": "http://example.com",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "mode": "dir",
  "extensions": "php,html,txt"
}
```

### Brute force com autenticação de sessão
```json
{
  "url": "https://example.com",
  "wordlist": "/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt",
  "mode": "dir",
  "extensions": "php,asp,aspx",
  "options": "-c 'PHPSESSID=abc123' -t 30 -s '200,301,302,403'"
}
```

### Enumeração de subdomínios DNS
```json
{
  "url": "",
  "wordlist": "/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt",
  "mode": "dns",
  "extensions": "",
  "options": "-d example.com -t 50"
}
```

### Descoberta de virtual hosts
```json
{
  "url": "http://10.10.10.5",
  "wordlist": "/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt",
  "mode": "vhost",
  "extensions": "",
  "options": "-t 30 --append-domain"
}
```

### Scan em HTTPS ignorando certificado
```json
{
  "url": "https://192.168.1.50",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "mode": "dir",
  "extensions": "php,html",
  "options": "-k -t 20 -o /tmp/gobuster_results.txt"
}
```

## OPSEC

- Use `--delay` para adicionar pausa entre requisições e evitar rate limiting
- `-t` alto (>50) pode sobrecarregar servidores frágeis
- Em ambientes com WAF, use `-t 10` e `--delay 200` para manter furtividade
- Combine com wafw00f antes para identificar presença de WAF

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Cada linha do stdout representa um caminho encontrado com status HTTP e tamanho
