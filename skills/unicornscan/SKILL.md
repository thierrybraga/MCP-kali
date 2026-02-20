---
name: "unicornscan"
description: "Scanner de portas assíncrono. Use quando precisar de scanning TCP/UDP com controle fino de pacotes ou como alternativa ao nmap."
---

# unicornscan

## Objetivo

- Scanning assíncrono de portas TCP e UDP com controle fino de pacotes
- Alternativa ao nmap para cenários que exigem maior customização
- Suporte a banner grabbing e fingerprinting de SO
- Scanning distribuído com múltiplos agentes

## Endpoint

- /api/tools/run

## Requer target

- sim

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                          |
|-----------|--------|-------------|-------------------------------------|
| tool      | string | sim         | "unicornscan"                       |
| target    | string | sim         | IP ou range CIDR alvo               |
| options   | string | não         | Flags adicionais do CLI             |

## Flags Importantes

| Flag              | Efeito                                              |
|-------------------|-----------------------------------------------------|
| `-mT`             | Modo TCP                                            |
| `-mU`             | Modo UDP                                            |
| `-mS`             | TCP SYN scan                                        |
| `-p 1-65535`      | Range de portas                                     |
| `-r N`            | Packets per second (taxa de envio)                  |
| `-R N`            | Retransmissões                                      |
| `-I`              | Modo interativo (resultados em tempo real)          |
| `-l arquivo`      | Salvar log em arquivo                               |
| `-v`              | Verbose                                             |

## Exemplos

### Scan TCP SYN básico
```json
{
  "tool": "unicornscan",
  "target": "192.168.1.10",
  "options": "-mT -p 1-1024 -r 100"
}
```

### Scan UDP em portas críticas
```json
{
  "tool": "unicornscan",
  "target": "10.10.10.5",
  "options": "-mU -p 53,161,500 -r 50"
}
```

### Scan completo com log
```json
{
  "tool": "unicornscan",
  "target": "192.168.1.0/24",
  "options": "-mT -p 1-65535 -r 200 -l /tmp/unicornscan.log"
}
```

## OPSEC

- Taxa alta de pacotes pode derrubar dispositivos de rede frágeis
- Scanning UDP é lento — restrinja às portas críticas (53, 161, 500, 1900)
- Prefira nmap para a maioria dos cenários; use unicornscan para casos específicos de controle de pacotes

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
