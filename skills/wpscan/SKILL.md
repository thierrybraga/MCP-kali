---
name: "wpscan"
description: "Executa WordPress vulnerability scanner. Use quando precisar executar wpscan via API."
---

# wpscan

Objetivo

- WordPress vulnerability scanner
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/web/wpscan

Requer target

- não

Parâmetros

- url: URL alvo
- options: flags do CLI para ajuste fino

Eficiência

- Defina o escopo antes de executar
- Use opções mínimas para reduzir ruído

Exemplo

```json
{
  "url": "http://wordpress-site.com",
  "options": "--enumerate p,t,u"
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
