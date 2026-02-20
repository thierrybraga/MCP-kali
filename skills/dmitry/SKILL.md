---
name: "dmitry"
description: "Executa Information gathering. Use quando precisar executar dmitry via API."
---

# dmitry

Objetivo

- Information gathering
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

- Comece com varredura passiva quando possível
- Reduza o escopo para subdomínios/alvos relevantes
- Evite wordlists enormes na primeira passagem

Exemplo

```json
{
  "tool": "dmitry",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
