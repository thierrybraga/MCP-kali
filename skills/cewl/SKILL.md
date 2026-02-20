---
name: "cewl"
description: "Executa Custom wordlist generator. Use quando precisar executar cewl via API."
---

# cewl

Objetivo

- Custom wordlist generator
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

- Valide o serviço e a porta antes de bruteforce
- Use wordlists enxutas no primeiro teste
- Aplique limites para evitar bloqueio do alvo

Exemplo

```json
{
  "tool": "cewl",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
