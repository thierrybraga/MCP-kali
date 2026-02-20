---
name: "recon-ng"
description: "Executa Reconnaissance framework. Use quando precisar executar recon-ng via API."
---

# recon-ng

Objetivo

- Reconnaissance framework
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Comece com varredura passiva quando possível
- Reduza o escopo para subdomínios/alvos relevantes
- Evite wordlists enormes na primeira passagem

Exemplo

```json
{
  "tool": "recon-ng",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
