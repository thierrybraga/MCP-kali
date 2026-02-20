---
name: "masscan"
description: "Scanner de portas de alta velocidade. Use para varredura rápida de grandes ranges de IP quando velocidade é prioridade sobre precisão."
---

# masscan

## Objetivo

- Varredura de portas TCP/UDP em velocidade extremamente alta (milhões de pacotes/s)
- Descoberta de hosts ativos em redes grandes (/8, /16)
- Identificação rápida de superfície de ataque antes de scans mais detalhados (nmap)
- Ideal para fases de recon externo em grandes escopos

## Endpoint

- /api/scan/masscan

## Requer target

- sim

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                              |
|-----------|--------|-------------|----------------------------------------|
| target    | string | sim         | IP, range CIDR ou arquivo de IPs       |
| ports     | string | não         | Faixa de portas (ex: "1-1000", "80,443") |
| rate      | string | não         | Pacotes por segundo (padrão: "1000")   |
| options   | string | não         | Flags adicionais do CLI masscan        |

## Flags Importantes

| Flag                    | Efeito                                              |
|-------------------------|-----------------------------------------------------|
| `-p 80,443,22`          | Portas específicas                                  |
| `-p 1-65535`            | Todas as portas                                     |
| `--rate N`              | Pacotes por segundo (cuidado: pode derrubar redes)  |
| `--top-ports N`         | Top N portas mais comuns                            |
| `-oJ arquivo`           | Output JSON                                         |
| `-oX arquivo`           | Output XML (compatível com nmap)                    |
| `-oG arquivo`           | Output grepable                                     |
| `--banners`             | Capturar banners de serviços (mais lento)           |
| `--exclude IP`          | Excluir host/range do scan                          |
| `--resume`              | Retomar scan pausado                                |
| `-e interface`          | Interface de rede a usar                            |

## Exemplos

### Descoberta rápida nas portas mais comuns
```json
{
  "target": "192.168.1.0/24",
  "ports": "1-1000",
  "rate": "1000"
}
```

### Scan completo de todas as portas
```json
{
  "target": "10.0.0.0/16",
  "ports": "1-65535",
  "rate": "5000",
  "options": "-oJ /tmp/masscan_full.json"
}
```

### Scan de portas web e SSH
```json
{
  "target": "172.16.0.0/12",
  "ports": "22,80,443,8080,8443",
  "rate": "2000"
}
```

### Scan com banners para detecção de serviços
```json
{
  "target": "192.168.100.0/24",
  "ports": "21,22,25,80,443,3306,5432",
  "rate": "500",
  "options": "--banners -oJ /tmp/masscan_banners.json"
}
```

## OPSEC

- `rate` alto (>10000) pode causar DoS acidental em redes frágeis — use com cautela
- Masscan é **muito barulhento** e facilmente detectado por firewalls e IDS
- Use taxas baixas (500-2000) em redes de produção mesmo com autorização
- Combine masscan (discovery) + nmap (enumeração detalhada) para eficiência
- Sempre exclua hosts críticos com `--exclude` (ex: gateways, firewalls)

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Output XML é compatível com ferramentas que consomem formato nmap
