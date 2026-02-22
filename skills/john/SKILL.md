---
name: "john"
description: "John the Ripper — cracker de hashes de senha offline. Suporta LM, NTLM, MD5, SHA, bcrypt, WPA e centenas de outros formatos. Usa ataques de dicionário, regras e força bruta."
---

# john

## Objetivo

- Quebrar hashes de senhas offline
- Suporta formatos: LM, NTLM, MD5, SHA-1/256/512, bcrypt, WPA, ZIP, PDF e +400 formatos
- Ataques de dicionário, regras de mutação e brute force puro
- Processar arquivos /etc/passwd e /etc/shadow do Linux
- Crack de hashes de Windows SAM, Active Directory

## Endpoint

- /api/tools/run (tool: "john")

## Requer target

- sim (arquivo de hashes)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | sim         | Arquivo com hashes para quebrar           |
| options   | string | não         | Flags adicionais do CLI john              |

## Flags Importantes

| Flag                    | Efeito                                                    |
|-------------------------|-----------------------------------------------------------|
| `--wordlist=<file>`     | Arquivo wordlist para ataque de dicionário                |
| `--rules[=<nome>]`      | Aplicar regras de mutação (ex: --rules=best64)            |
| `--format=<fmt>`        | Forçar formato do hash (ex: NT, md5crypt, bcrypt)         |
| `--show`                | Exibir senhas já quebradas                                |
| `--pot=<arquivo>`       | Arquivo pot customizado                                   |
| `--incremental[=<set>]` | Modo brute force incremental                              |
| `--mask=<máscara>`      | Ataque por máscara (ex: ?l?l?l?d?d)                      |
| `--fork=<n>`            | Usar N processos paralelos                                |
| `--list=formats`        | Listar todos os formatos suportados                       |
| `--session=<nome>`      | Nomear sessão para retomar depois                         |
| `--restore[=<nome>]`    | Retomar sessão anterior                                   |
| `--status`              | Ver status da sessão atual                                |

## Exemplos

### Dicionário básico com rockyou
```json
{
  "tool": "john",
  "target": "/root/hashes/shadow.txt",
  "options": "--wordlist=/root/wordlists/rockyou.txt"
}
```

### Hashes NTLM (Windows)
```json
{
  "tool": "john",
  "target": "/root/hashes/ntlm.txt",
  "options": "--format=NT --wordlist=/root/wordlists/rockyou.txt --rules=best64"
}
```

### Linux shadow com regras
```json
{
  "tool": "john",
  "target": "/root/hashes/shadow.txt",
  "options": "--wordlist=/root/wordlists/rockyou.txt --rules=jumbo"
}
```

### Exibir senhas já quebradas
```json
{
  "tool": "john",
  "target": "/root/hashes/shadow.txt",
  "options": "--show"
}
```

### Brute force incremental (alfanumérico)
```json
{
  "tool": "john",
  "target": "/root/hashes/md5.txt",
  "options": "--format=raw-md5 --incremental=alnum"
}
```

### Combinar shadow com passwd
```bash
unshadow /etc/passwd /etc/shadow > /root/hashes/combined.txt
```
```json
{
  "tool": "john",
  "target": "/root/hashes/combined.txt",
  "options": "--wordlist=/root/wordlists/rockyou.txt"
}
```

## Formatos Comuns

| Formato       | Hash                          |
|---------------|-------------------------------|
| NT            | Windows NTLM                  |
| LM            | Windows LM legacy             |
| md5crypt      | Linux MD5 ($1$)               |
| sha512crypt   | Linux SHA512 ($6$)            |
| bcrypt        | bcrypt ($2a$)                 |
| raw-md5       | MD5 sem salt                  |
| raw-sha1      | SHA-1 sem salt                |
| raw-sha256    | SHA-256 sem salt              |
| WPA-PMKID     | Handshake WPA capturado       |
| ZIP           | Arquivo ZIP protegido         |

## Workflow com Hashdump

1. Capturar hashes (Metasploit `hashdump` ou `secretsdump`)
2. Salvar em arquivo `/root/hashes/dump.txt`
3. Rodar John: `--format=NT --wordlist=rockyou.txt`
4. Ver resultados: `--show --format=NT`

## OPSEC

- Ataque offline — sem detecção na rede
- Use `--fork=4` para aproveitar múltiplos CPUs
- Sessões nomeadas com `--session` permitem pausar/retomar
- Combine dicionário + regras antes de brute force puro
- Para hashes bcrypt, prefira hashcat com GPU

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Senhas encontradas: `hash:senha` no stdout
- `--show` exibe lista completa de quebradas
