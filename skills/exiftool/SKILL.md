---
name: "exiftool"
description: "Executa Metadata extraction. Use quando precisar executar exiftool via API."
---

# exiftool

Objetivo

- Metadata extraction
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
  "tool": "exiftool",
  "target": "example.com",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
