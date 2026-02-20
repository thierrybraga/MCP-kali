---
name: "dirb"
description: "Scanner de diretórios web por brute force. Use para descoberta rápida de caminhos em servidores web com suporte a autenticação e proxies."
---

# dirb

## Objetivo

- Descoberta de diretórios e arquivos ocultos em servidores web
- Suporte a autenticação HTTP básica e NTLM
- Scanning recursivo automático de diretórios encontrados
- Uso de wordlists customizadas ou padrão

## Endpoint

- /api/web/dirb

## Requer target

- não

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                        |
|-----------|--------|-------------|--------------------------------------------------|
| url       | string | sim         | URL base do alvo (ex: http://example.com)        |
| wordlist  | string | não         | Caminho para wordlist (padrão: dirb/common.txt)  |
| options   | string | não         | Flags adicionais do CLI dirb                     |

## Flags Importantes

| Flag              | Efeito                                                |
|-------------------|-------------------------------------------------------|
| `-r`              | Não fazer scanning recursivo                          |
| `-R`              | Scanning recursivo interativo                         |
| `-o arquivo`      | Salvar output em arquivo                              |
| `-a "User-Agent"` | User-Agent customizado                                |
| `-c "Cookie"`     | Enviar cookie de sessão                               |
| `-H "Header"`     | Cabeçalho HTTP customizado                            |
| `-u user:pass`    | Autenticação HTTP básica                              |
| `-p proxy:port`   | Usar proxy HTTP                                       |
| `-S`              | Silent mode (sem progress bar)                        |
| `-N código`       | Ignorar respostas com este código HTTP                |
| `-x extensões`    | Arquivo de extensões a testar                         |
| `-z`              | Não fazer requests de cache                           |
| `-t`              | Não usar cabeçalhos automáticos de User-Agent         |

## Wordlists Padrão do Kali

| Wordlist                                           | Uso                      |
|----------------------------------------------------|--------------------------|
| `/usr/share/wordlists/dirb/common.txt`             | Geral rápido             |
| `/usr/share/wordlists/dirb/big.txt`                | Cobertura ampla          |
| `/usr/share/wordlists/dirb/small.txt`              | Scan mínimo              |
| `/usr/share/wordlists/dirb/extensions_common.txt`  | Lista de extensões       |

## Exemplos

### Scan básico com wordlist padrão
```json
{
  "url": "http://example.com",
  "wordlist": "/usr/share/wordlists/dirb/common.txt"
}
```

### Scan com extensões e output
```json
{
  "url": "http://192.168.1.50",
  "wordlist": "/usr/share/wordlists/dirb/big.txt",
  "options": "-x /usr/share/wordlists/dirb/extensions_common.txt -o /tmp/dirb_results.txt"
}
```

### Scan com autenticação e cookie
```json
{
  "url": "http://example.com/admin",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "options": "-u admin:password -c 'session=abc123'"
}
```

### Scan via proxy (Burp Suite)
```json
{
  "url": "https://example.com",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "options": "-p 127.0.0.1:8080 -N 404"
}
```

### Scan sem recursão (mais rápido)
```json
{
  "url": "http://target.com",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "options": "-r -S"
}
```

## OPSEC

- dirb é single-threaded — mais lento que ffuf/gobuster mas mais furtivo
- Use `-N 404` para filtrar respostas não encontradas e limpar output
- Prefira ffuf ou feroxbuster para escopos grandes; dirb para scans rápidos e pontuais
- Combine com nikto para análise mais ampla do servidor

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Cada linha indica o caminho encontrado com código HTTP e tamanho
