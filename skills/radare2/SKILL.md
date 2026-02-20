---
name: "radare2"
description: "Executa Reverse engineering. Use quando precisar executar radare2 via API."
---

# radare2

Objetivo

- Reverse engineering
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

- Trabalhe em cópias e preserve integridade
- Use hash para validação de evidências
- Minimize alterações no artefato original

Exemplo

```json
{
  "tool": "radare2",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
