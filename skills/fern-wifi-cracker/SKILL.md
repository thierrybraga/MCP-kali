---
name: "fern-wifi-cracker"
description: "Executa Wireless attack tool. Use quando precisar executar fern-wifi-cracker via API."
---

# fern-wifi-cracker

Objetivo

- Wireless attack tool
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Confirme que o ambiente é autorizado e controlado
- Restrinja canais para reduzir tempo de captura
- Evite ataques prolongados sem necessidade

Exemplo

```json
{
  "tool": "fern-wifi-cracker",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
