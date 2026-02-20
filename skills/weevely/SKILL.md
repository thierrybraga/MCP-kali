---
name: "weevely"
description: "Executa Web shell. Use quando precisar executar weevely via API."
---

# weevely

Objetivo

- Web shell
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
  "tool": "weevely",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
