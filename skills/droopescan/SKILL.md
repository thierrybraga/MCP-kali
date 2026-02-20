---
name: "droopescan"
description: "Executa CMS scanner. Use quando precisar executar droopescan via API."
---

# droopescan

Objetivo

- CMS scanner
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
  "tool": "droopescan",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
