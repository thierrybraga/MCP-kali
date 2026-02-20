---
name: "lazagne"
description: "Executa Credential recovery. Use quando precisar executar lazagne via API."
---

# lazagne

Objetivo

- Credential recovery
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Foque em coleta mínima necessária
- Evite ações destrutivas ou persistência
- Registre cada comando para auditoria

Exemplo

```json
{
  "tool": "lazagne",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
