---
name: "httpx"
description: "Executa HTTP probing toolkit. Use quando precisar executar httpx via API."
---

# httpx

Objetivo

- HTTP probing toolkit
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/web/httpx

Requer target

- sim

Parâmetros

- target: alvo principal
- options: flags do CLI para ajuste fino

Eficiência

- Defina o escopo antes de executar
- Use opções mínimas para reduzir ruído

Exemplo

```json
{
  "target": "https://example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
