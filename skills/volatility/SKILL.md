---
name: "volatility"
description: "Executa Memory forensics. Use quando precisar executar volatility via API."
---

# volatility

Objetivo

- Memory forensics
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Trabalhe em cópias e preserve integridade
- Use hash para validação de evidências
- Minimize alterações no artefato original

Exemplo

```json
{
  "tool": "volatility",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
