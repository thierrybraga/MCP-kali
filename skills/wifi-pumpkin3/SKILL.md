---
name: "wifi-pumpkin3"
description: "Executa Rogue AP framework. Use quando precisar executar wifi-pumpkin3 via API."
---

# wifi-pumpkin3

Objetivo

- Rogue AP framework
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
  "tool": "wifi-pumpkin3",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
