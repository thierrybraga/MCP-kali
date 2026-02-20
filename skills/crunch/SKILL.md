---
name: "crunch"
description: "Executa Wordlist generator. Use quando precisar executar crunch via API."
---

# crunch

Objetivo

- Wordlist generator
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Valide o serviço e a porta antes de bruteforce
- Use wordlists enxutas no primeiro teste
- Aplique limites para evitar bloqueio do alvo

Exemplo

```json
{
  "tool": "crunch",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
