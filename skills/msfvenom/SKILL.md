---
name: "msfvenom"
description: "Executa Payload generator. Use quando precisar executar msfvenom via API."
---

# msfvenom

Objetivo

- Payload generator
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/tools/run

Requer target

- não

Parâmetros

- tool: nome da ferramenta
- options: flags do CLI para ajuste fino

Eficiência

- Execute apenas com autorização e escopo definido
- Use configuração mínima antes de variar payloads
- Registre parâmetros para reprodutibilidade

Exemplo

```json
{
  "tool": "msfvenom",
  "options": ""
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
