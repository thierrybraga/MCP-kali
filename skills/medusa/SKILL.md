---
name: "medusa"
description: "Cracker paralelo de autenticação de rede. Alternativa ao Hydra com foco em velocidade e paralelismo. Suporta SSH, FTP, HTTP, MySQL, RDP e dezenas de outros protocolos."
---

# medusa

## Objetivo

- Ataques de força bruta paralelos contra serviços de rede
- Testar credenciais em múltiplos hosts simultaneamente
- Suporte a SSH, FTP, Telnet, HTTP, HTTPS, SMB, MySQL, MSSQL, PostgreSQL, RDP, VNC, SMTP, POP3, IMAP
- Controle fino de threads e velocidade de ataque

## Endpoint

- /api/tools/run (tool: "medusa")

## Requer target

- sim

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | sim         | IP ou hostname do host alvo               |
| options   | string | sim         | Flags do CLI medusa (incluindo -M serviço)|

## Flags Importantes

| Flag              | Efeito                                                    |
|-------------------|-----------------------------------------------------------|
| `-h <host>`       | Host alvo (IP ou hostname)                                |
| `-H <hostlist>`   | Arquivo com lista de hosts                                |
| `-u <user>`       | Usuário único para ataque                                 |
| `-U <userlist>`   | Arquivo com lista de usuários                             |
| `-p <pass>`       | Senha única para ataque                                   |
| `-P <passlist>`   | Arquivo com lista de senhas                               |
| `-M <módulo>`     | Módulo do serviço: ssh, ftp, http, mysql, mssql, rdp     |
| `-t <threads>`    | Threads por host (default: 1)                             |
| `-T <hosts>`      | Hosts simultâneos (default: 1)                            |
| `-n <porta>`      | Porta customizada                                         |
| `-s`              | SSL/TLS                                                   |
| `-f`              | Parar ao encontrar credencial válida para o host          |
| `-F`              | Parar ao encontrar qualquer credencial válida             |
| `-v N`            | Verbosidade (0-6)                                         |
| `-O <arquivo>`    | Salvar resultados em arquivo                              |

## Exemplos

### SSH básico
```json
{
  "tool": "medusa",
  "target": "192.168.1.100",
  "options": "-h 192.168.1.100 -u root -P /root/wordlists/rockyou.txt -M ssh -t 4 -f"
}
```

### FTP com lista de usuários
```json
{
  "tool": "medusa",
  "target": "192.168.1.50",
  "options": "-h 192.168.1.50 -U /root/wordlists/users.txt -P /root/wordlists/rockyou.txt -M ftp -t 8"
}
```

### HTTP Basic Auth
```json
{
  "tool": "medusa",
  "target": "192.168.1.100",
  "options": "-h 192.168.1.100 -u admin -P /root/wordlists/rockyou.txt -M http -m DIR:/admin -t 4"
}
```

### MySQL em porta customizada
```json
{
  "tool": "medusa",
  "target": "10.10.10.5",
  "options": "-h 10.10.10.5 -u root -P /root/wordlists/rockyou.txt -M mysql -n 3306 -f"
}
```

### Múltiplos hosts simultâneos
```json
{
  "tool": "medusa",
  "target": "hosts.txt",
  "options": "-H /root/targets/hosts.txt -u admin -P /root/wordlists/rockyou.txt -M ssh -T 5 -t 4 -F"
}
```

## Módulos Disponíveis

| Módulo   | Serviço                     |
|----------|-----------------------------|
| ssh      | SSH (porta 22)              |
| ftp      | FTP (porta 21)              |
| http     | HTTP Basic Auth             |
| https    | HTTPS Basic Auth            |
| smb      | SMB/Windows shares          |
| mysql    | MySQL (porta 3306)          |
| mssql    | Microsoft SQL Server        |
| postgres | PostgreSQL                  |
| rdp      | Remote Desktop              |
| vnc      | VNC                         |
| smtp     | SMTP                        |
| pop3     | POP3                        |
| imap     | IMAP                        |
| telnet   | Telnet                      |
| snmp     | SNMP                        |

## OPSEC

- Use `-t 1` para minimizar detecção por IDS
- `-F` para em qualquer credencial válida — use em CTFs e labs
- Em ambientes AD, cuidado com lockout: limite tentativas por conta
- Combine com `-O output.txt` para manter log de credenciais
- Prefira wordlists direcionadas (ex: cewl) antes de rockyou

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Credenciais válidas: `ACCOUNT FOUND: [serviço] Host: IP User: user Password: pass`
