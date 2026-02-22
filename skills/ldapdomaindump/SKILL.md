---
name: "ldapdomaindump"
description: "Enumeração completa de domínio Active Directory via LDAP. Extrai usuários, grupos, computadores, GPOs, OUs, políticas de senha e informações de domínio em formato JSON/HTML/CSV. Ideal para reconhecimento AD pós-acesso com credenciais válidas."
---

# ldapdomaindump

## Objetivo

- Enumerar todos os objetos do Active Directory via LDAP autenticado
- Extrair usuários, grupos, computadores e membros de grupos
- Capturar políticas de senha, GPOs e OUs
- Gerar relatórios em JSON, CSV e HTML para análise offline
- Identificar usuários privilegiados (Domain Admins, Enterprise Admins)
- Mapear membros de grupos críticos de segurança

## Endpoint

- /api/tools/run (tool: "ldapdomaindump")
- /api/tools/dry-run (tool: "ldapdomaindump")

## Requer target

- sim (IP ou hostname do Domain Controller)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                  |
|-----------|--------|-------------|---------------------------------------------|
| target    | string | sim         | IP ou hostname do Domain Controller          |
| options   | string | sim         | Flags incluindo credenciais -u e -p          |

## Flags Importantes

| Flag                      | Descrição                                                              |
|---------------------------|------------------------------------------------------------------------|
| `-u DOMAIN\user`          | Usuário para autenticação LDAP (formato DOMAIN\user ou user@domain)    |
| `-p password`             | Senha do usuário                                                       |
| `-o /output/dir`          | Diretório de saída para os dumps (padrão: diretório atual)             |
| `--no-json`               | Não gerar arquivos JSON                                                |
| `--no-html`               | Não gerar arquivos HTML                                                |
| `--no-grep`               | Não gerar arquivos grepáveis (.grep)                                   |
| `-at {NTLM,SIMPLE}`       | Tipo de autenticação (padrão: NTLM)                                    |
| `--dns-tcp`               | Forçar resolução DNS via TCP                                           |
| `-l`                      | Usar conexão LDAPS (porta 636)                                         |

## Dados Coletados

| Arquivo gerado               | Conteúdo                                              |
|------------------------------|-------------------------------------------------------|
| `domain_users.json`          | Todos os usuários do domínio com atributos completos  |
| `domain_groups.json`         | Todos os grupos e seus membros                        |
| `domain_computers.json`      | Máquinas ingressadas no domínio                       |
| `domain_policy.json`         | Política de senha do domínio                          |
| `domain_trusts.json`         | Trusts entre domínios                                 |
| `domain_controllers.json`    | Domain Controllers identificados                      |
| `domain_users_by_group.json` | Mapeamento usuário → grupos                           |
| `*.html`                     | Relatórios HTML navegáveis para cada categoria        |
| `*.grep`                     | Versão texto simples para grep/awk                    |

## Exemplos

### Dump completo com autenticação NTLM

```json
{
  "tool": "ldapdomaindump",
  "target": "192.168.1.10",
  "options": "-u 'CORP\\admin' -p Password123 -o /tmp/ldd_results/"
}
```

### Dump com autenticação UPN (user@domain)

```json
{
  "tool": "ldapdomaindump",
  "target": "192.168.1.10",
  "options": "-u admin@corp.local -p Password123 -o /tmp/ldd_results/"
}
```

### Dump via LDAPS (porta 636)

```json
{
  "tool": "ldapdomaindump",
  "target": "192.168.1.10",
  "options": "-u 'CORP\\admin' -p Password123 -l -o /tmp/ldd_results/"
}
```

### Dry-run (verificar comando sem executar)

```json
{
  "tool": "ldapdomaindump",
  "target": "192.168.1.10",
  "options": "-u 'CORP\\admin' -p Password123"
}
```

## Workflow Típico

```
1. Obter credenciais válidas (phishing, brute force, Responder)
2. Executar ldapdomaindump contra o DC:
   ldapdomaindump -u 'CORP\admin' -p Password123 -o /tmp/ldd/ 192.168.1.10
3. Analisar domain_users.json para contas privilegiadas
4. Verificar domain_policy.json para política de lockout
5. Cruzar com BloodHound para mapear caminhos de ataque
```

## OPSEC

- Gera consultas LDAP volumosas — detectável em SIEM com alertas LDAP
- Use `-at SIMPLE` apenas em redes internas (credenciais em texto claro)
- Prefira `-l` (LDAPS) para evitar credenciais em trânsito sem criptografia
- O dump completo pode demorar vários minutos em domínios grandes
- Logs de autenticação LDAP ficam no Event Log do DC (Event ID 4625/4624)
- Evite executar durante horário comercial em ambientes sensíveis

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- `artifacts`: lista de arquivos gerados no diretório `-o`
- `report`: resumo com total de usuários, grupos e computadores enumerados
