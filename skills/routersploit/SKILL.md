---
name: "routersploit"
description: "Executa Router exploitation framework. Use quando precisar executar routersploit via API."
---

# routersploit

Objetivo

- Router exploitation framework
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Execute apenas com autorização e escopo definido
- Use configuração mínima antes de variar payloads
- Registre parâmetros para reprodutibilidade

Exemplo

```json
{
  "tool": "routersploit",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
