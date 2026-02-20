---
name: "pixiewps"
description: "Executa WPS pin recovery. Use quando precisar executar pixiewps via API."
---

# pixiewps

Objetivo

- WPS pin recovery
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
  "tool": "pixiewps",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
