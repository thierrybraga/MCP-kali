---
name: "enum4linux"
description: "Executa SMB enumeration. Use quando precisar executar enum4linux via API."
---

# enum4linux

Objetivo

- SMB enumeration
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
  "tool": "enum4linux",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
