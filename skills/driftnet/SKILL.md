---
name: "driftnet"
description: "Executa Traffic image sniffer. Use quando precisar executar driftnet via API."
---

# driftnet

Objetivo

- Traffic image sniffer
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
  "tool": "driftnet",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
