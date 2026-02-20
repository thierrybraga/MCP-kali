---
name: "beef-xss"
description: "Executa Browser exploitation framework. Use quando precisar executar beef-xss via API."
---

# beef-xss

Objetivo

- Browser exploitation framework
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Priorize URLs específicas e endpoints críticos
- Use opções de timeout para evitar espera desnecessária
- Limite concorrência antes de aumentar agressividade

Exemplo

```json
{
  "tool": "beef-xss",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
