---
name: "nmap"
description: "Scanner de portas e serviços de rede. Use para descoberta de hosts, enumeração de portas, detecção de versões e scripts NSE."
---

# nmap

## Objetivo

- Descoberta de hosts ativos na rede
- Enumeração de portas abertas (TCP/UDP)
- Detecção de versões de serviços (-sV)
- Identificação de sistema operacional (-O)
- Execução de scripts NSE para enumeração avançada (-sC / --script)

## Endpoint

- /api/scan/nmap

## Requer target

- sim

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | sim         | IP, range CIDR ou hostname alvo           |
| options   | string | não         | Flags adicionais do CLI nmap              |
| output    | string | não         | Formato: normal, xml, grepable, json      |

## Flags Importantes

| Flag              | Efeito                                                    |
|-------------------|-----------------------------------------------------------|
| `-sS`             | SYN scan (stealth, padrão root)                           |
| `-sT`             | TCP connect scan (sem root)                               |
| `-sU`             | UDP scan                                                  |
| `-sV`             | Detecção de versão de serviço                             |
| `-sC`             | Scripts NSE padrão                                        |
| `-O`              | Detecção de sistema operacional                           |
| `-A`              | Agressivo: OS, versão, scripts, traceroute                |
| `-p-`             | Todas as 65535 portas                                     |
| `-p 22,80,443`    | Portas específicas                                        |
| `--top-ports N`   | Top N portas mais comuns                                  |
| `-T0` a `-T5`     | Timing: T0=paranóico, T3=normal, T4=agressivo             |
| `-Pn`             | Pular descoberta de host (tratar como ativo)              |
| `--script vuln`   | Rodar scripts de vulnerabilidade                          |
| `-oA <base>`      | Output em todos formatos                                  |
| `--min-rate N`    | Mínimo de pacotes por segundo                             |

## Exemplos

### Scan rápido inicial
```json
{
  "target": "192.168.1.0/24",
  "options": "-sn",
  "output": "normal"
}
```

### Scan de serviços nas portas comuns
```json
{
  "target": "10.10.10.5",
  "options": "-sV -sC --top-ports 1000 -T4",
  "output": "xml"
}
```

### Scan completo com scripts de vulnerabilidade
```json
{
  "target": "192.168.1.50",
  "options": "-sV -sC -O -p- --script vuln -T4",
  "output": "xml"
}
```

### Scan UDP nos serviços críticos
```json
{
  "target": "192.168.1.50",
  "options": "-sU -p 53,161,500,1900 -sV",
  "output": "normal"
}
```

### Scan furtivo (baixo ruído)
```json
{
  "target": "10.0.0.1",
  "options": "-sS -T2 -Pn --data-length 15",
  "output": "grepable"
}
```

## OPSEC

- Use `-T2` ou `-T1` em ambientes sensíveis para reduzir detecção por IDS/IPS
- Evite `-A` em scans iniciais; prefira dividir em fases
- `--script vuln` gera muito ruído — use apenas quando autorizado
- Registre sempre o output com `-oA` para evidências do pentest

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- O campo `report` contém o resultado parseado (hosts, portas, serviços)
- `artifacts` contém caminhos para arquivos de output salvos
