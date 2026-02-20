---
name: "sslscan"
description: "Executa SSL/TLS scanner. Use quando precisar executar sslscan via API."
---

# sslscan

Objetivo

- SSL/TLS scanner
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
  "tool": "sslscan",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
