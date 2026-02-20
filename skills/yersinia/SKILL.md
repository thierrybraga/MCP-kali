---
name: "yersinia"
description: "Executa Layer 2 attack tool. Use quando precisar executar yersinia via API."
---

# yersinia

Objetivo

- Layer 2 attack tool
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Limite interfaces e filtros para reduzir ruído
- Capture apenas o tráfego necessário
- Armazene evidências com timestamps

Exemplo

```json
{
  "tool": "yersinia",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
