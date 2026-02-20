---
name: "davtest"
description: "Executa WebDAV tester. Use quando precisar executar davtest via API."
---

# davtest

Objetivo

- WebDAV tester
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- sim

Parâmetros

- tool: nome da ferramenta
- target: alvo principal
- options: flags do CLI para ajuste fino

Eficiência

- Priorize URLs específicas e endpoints críticos
- Use opções de timeout para evitar espera desnecessária
- Limite concorrência antes de aumentar agressividade

Exemplo

```json
{
  "tool": "davtest",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
