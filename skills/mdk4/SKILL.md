---
name: "mdk4"
description: "Executa Wireless testing. Use quando precisar executar mdk4 via API."
---

# mdk4

Objetivo

- Wireless testing
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
  "tool": "mdk4",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
