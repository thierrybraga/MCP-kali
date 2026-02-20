---
name: "bettercap"
description: "Executa MITM framework. Use quando precisar executar bettercap via API."
---

# bettercap

Objetivo

- MITM framework
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
  "tool": "bettercap",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
