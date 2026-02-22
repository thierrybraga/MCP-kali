---
name: "hashcat"
description: "Cracker de hashes GPU-acelerado — o mais rápido do mundo. Suporta MD5, SHA, NTLM, bcrypt, WPA, NetNTLMv2 e +350 formatos. Ataques: dicionário, regras, máscara, combinação e brute force."
---

# hashcat

## Objetivo

- Quebrar hashes de senha com aceleração GPU (CUDA/OpenCL)
- Suporta +350 formatos de hash
- Ataques: dicionário (-a 0), combinação (-a 1), brute force (-a 3), híbrido (-a 6/-a 7)
- Regras de mutação avançadas (ex: best64, dive, OneRuleToRuleThemAll)
- Crack de WPA/WPA2 handshakes e PMKID
- Processar hashes NTLM, NetNTLMv2, bcrypt, SHA-crypt

## Endpoint

- /api/tools/run (tool: "hashcat")

## Requer target

- sim (arquivo de hashes)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | sim         | Arquivo com hashes para quebrar           |
| options   | string | sim         | Flags do CLI hashcat (tipo de ataque etc) |

## Flags Importantes

| Flag                    | Efeito                                                    |
|-------------------------|-----------------------------------------------------------|
| `-m <modo>`             | Tipo do hash (0=MD5, 1000=NTLM, 22000=WPA, 5600=NetNTLMv2)|
| `-a <ataque>`           | Modo: 0=dicionário, 1=combo, 3=máscara, 6=híbrido        |
| `-w <N>`                | Workload: 1=baixo, 3=médio, 4=máximo                      |
| `--wordlist <file>`     | Wordlist para ataque de dicionário                        |
| `-r <rules>`            | Arquivo de regras de mutação                              |
| `--show`                | Exibir hashes já quebrados                                |
| `--status`              | Exibir progresso em tempo real                            |
| `--session <nome>`      | Nomear sessão para retomar                                |
| `--restore`             | Retomar sessão anterior                                   |
| `-o <output>`           | Salvar senhas quebradas em arquivo                        |
| `--increment`           | Máscara incremental (aumenta tamanho)                     |
| `--force`               | Ignorar avisos de hardware                                |
| `-D 1`                  | Usar CPU (sem GPU)                                        |
| `-D 2`                  | Usar GPU                                                  |

## Modos de Hash (-m) Comuns

| Modo  | Tipo                        |
|-------|-----------------------------|
| 0     | MD5                         |
| 100   | SHA-1                       |
| 1000  | NTLM (Windows)              |
| 1800  | sha512crypt (Linux $6$)     |
| 3200  | bcrypt                      |
| 5600  | NetNTLMv2                   |
| 13100 | Kerberos TGS (Kerberoasting)|
| 18200 | Kerberos AS-REP (AS-REP)    |
| 22000 | WPA-PBKDF2-PMKID+Eapol      |

## Exemplos

### NTLM com rockyou
```json
{
  "tool": "hashcat",
  "target": "/root/hashes/ntlm.txt",
  "options": "-m 1000 -a 0 /root/hashes/ntlm.txt /root/wordlists/rockyou.txt -o /root/hashes/cracked.txt"
}
```

### NetNTLMv2 (Responder) com regras
```json
{
  "tool": "hashcat",
  "target": "/root/hashes/netntlmv2.txt",
  "options": "-m 5600 -a 0 /root/hashes/netntlmv2.txt /root/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule"
}
```

### WPA/WPA2 handshake
```json
{
  "tool": "hashcat",
  "target": "/root/captures/handshake.hccapx",
  "options": "-m 22000 -a 0 /root/captures/handshake.hccapx /root/wordlists/rockyou.txt"
}
```

### Kerberoasting TGS tickets
```json
{
  "tool": "hashcat",
  "target": "/root/hashes/kerberos.txt",
  "options": "-m 13100 -a 0 /root/hashes/kerberos.txt /root/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule"
}
```

### Máscara (senha com padrão: 8 chars alfanumérica)
```json
{
  "tool": "hashcat",
  "target": "/root/hashes/ntlm.txt",
  "options": "-m 1000 -a 3 /root/hashes/ntlm.txt ?a?a?a?a?a?a?a?a"
}
```

### Brute force incremental (1-8 chars)
```json
{
  "tool": "hashcat",
  "target": "/root/hashes/md5.txt",
  "options": "-m 0 -a 3 /root/hashes/md5.txt ?a?a?a?a?a?a?a?a --increment --increment-min 4"
}
```

## Charset para Máscara

| Char | Conjunto                    |
|------|-----------------------------|
| `?l` | abcdefghijklmnopqrstuvwxyz  |
| `?u` | ABCDEFGHIJKLMNOPQRSTUVWXYZ  |
| `?d` | 0123456789                  |
| `?s` | Símbolos especiais          |
| `?a` | Todos os caracteres         |

## OPSEC

- Hashcat opera offline — sem tráfego de rede
- Em VMs sem GPU, use `-D 1` (CPU) — bem mais lento
- `--session` permite pausar e retomar sessões longas
- OneRuleToRuleThemAll.rule é extremamente eficaz para senhas corporativas
- Combine dicionário + regras antes de máscaras (eficiência)

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Senhas encontradas: `hash:senha` no stdout e no arquivo `-o`
