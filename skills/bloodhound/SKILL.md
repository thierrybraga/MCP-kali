---
name: "bloodhound"
description: "Ferramenta de análise de caminhos de ataque em Active Directory. Coleta dados via SharpHound/bloodhound-python e visualiza relações de confiança, delegações e caminhos para Domain Admin."
---

# bloodhound

## Objetivo

- Mapear relações de confiança e permissões em Active Directory
- Identificar caminhos de ataque para Domain Admin / Enterprise Admin
- Descobrir delegações Kerberos inseguras (constrained/unconstrained)
- Encontrar ACLs exploráveis (WriteDACL, GenericAll, ForceChangePassword)
- Detectar grupos aninhados com privilégios excessivos
- Enumerar GPOs, OUs e trusts entre domínios/florestas

## Endpoint

- /api/tools/run (tool: "bloodhound-python")

## Requer target

- sim (domínio ou DC alvo)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                          |
|-----------|--------|-------------|----------------------------------------------------|
| target    | string | sim         | IP ou hostname do Domain Controller                |
| options   | string | sim         | Flags do bloodhound-python                         |

## Flags Importantes (bloodhound-python)

| Flag                  | Efeito                                                    |
|-----------------------|-----------------------------------------------------------|
| `-d <domínio>`        | Nome do domínio AD                                        |
| `-u <user>`           | Usuário para coleta                                       |
| `-p <pass>`           | Senha do usuário                                          |
| `-c <coleta>`         | Tipo: All, DCOnly, Default, Session, LoggedOn, Trusts     |
| `--dc <IP>`           | IP do Domain Controller                                   |
| `-ns <nameserver>`    | Servidor DNS customizado                                  |
| `-k`                  | Usar Kerberos (sem senha em texto)                        |
| `--hashes <hash>`     | Pass-the-Hash (LM:NT)                                     |
| `--zip`               | Compactar dados em ZIP para importar no BloodHound GUI    |
| `-o <diretório>`      | Diretório de output                                       |
| `--dns-timeout`       | Timeout DNS                                               |

## Exemplos

### Coleta completa com credenciais
```json
{
  "tool": "bloodhound-python",
  "target": "192.168.1.10",
  "options": "-d CORP.LOCAL -u john -p Password123 --dc 192.168.1.10 -c All --zip -o /root/reports/bh"
}
```

### Coleta somente do DC (mais rápido)
```json
{
  "tool": "bloodhound-python",
  "target": "192.168.1.10",
  "options": "-d CORP.LOCAL -u john -p Password123 --dc 192.168.1.10 -c DCOnly --zip"
}
```

### Com Pass-the-Hash
```json
{
  "tool": "bloodhound-python",
  "target": "192.168.1.10",
  "options": "-d CORP.LOCAL -u administrator --hashes aad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0 --dc 192.168.1.10 -c All --zip"
}
```

### Coleta de sessões ativas
```json
{
  "tool": "bloodhound-python",
  "target": "192.168.1.10",
  "options": "-d CORP.LOCAL -u john -p Password123 --dc 192.168.1.10 -c Session,LoggedOn --zip"
}
```

## Workflow Completo

1. **Coletar dados** com bloodhound-python (acima)
2. **Iniciar Neo4j**: `neo4j start`
3. **Abrir BloodHound GUI**: `bloodhound &`
4. **Importar ZIP** gerado na coleta
5. **Queries úteis**:
   - "Shortest Paths to Domain Admin"
   - "Find Principals with DCSync Rights"
   - "Find Computers with Unconstrained Delegation"
   - "Find AS-REP Roastable Users"

## OPSEC

- Coleta LDAP gera muitas queries ao DC — visível em logs de auditoria
- Use `-c DCOnly` para coleta mais silenciosa (sem acesso a workstations)
- Sessões (`-c Session`) requerem acesso a hosts individuais — muito ruidoso
- Prefira horários de pico para se misturar com tráfego legítimo
- Kerberos (`-k`) evita transmissão de senha em texto na rede

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Arquivos JSON/ZIP gerados em `/root/reports/bh/`
- Importar ZIP no BloodHound GUI para visualização de grafos
