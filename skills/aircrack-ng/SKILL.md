---
name: "aircrack-ng"
description: "Suite completa de auditoria de segurança WiFi. Captura de handshakes WPA/WPA2, crack de WEP/WPA, injeção de pacotes e análise de redes sem fio."
---

# aircrack-ng

## Objetivo

- Capturar handshakes WPA/WPA2 para crack offline
- Quebrar chaves WEP por análise de IVs
- Injeção de pacotes (deauth, replay, ARP injection)
- Monitorar redes WiFi em modo promíscuo
- Crack de hashes WPA com dicionário

## Endpoint

- /api/tools/run (tool: "aircrack-ng")

## Requer target

- sim (arquivo de captura .cap ou .ivs)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | sim         | Arquivo .cap/.ivs ou BSSID alvo           |
| options   | string | sim         | Flags do CLI aircrack-ng                  |

## Componentes da Suite

| Ferramenta      | Função                                         |
|-----------------|------------------------------------------------|
| `airmon-ng`     | Ativar/desativar modo monitor na interface     |
| `airodump-ng`   | Captura de pacotes e handshakes                |
| `aireplay-ng`   | Injeção de pacotes (deauth, replay)            |
| `aircrack-ng`   | Crack de WEP/WPA a partir de capturas          |
| `airdecap-ng`   | Descriptografar capturas WEP/WPA               |

## Flags do aircrack-ng

| Flag              | Efeito                                                    |
|-------------------|-----------------------------------------------------------|
| `-w <wordlist>`   | Wordlist para ataque WPA                                  |
| `-b <BSSID>`      | BSSID da rede alvo                                        |
| `-e <ESSID>`      | ESSID da rede alvo                                        |
| `-l <output>`     | Salvar chave encontrada em arquivo                        |
| `--bssid <MAC>`   | Filtrar por AP específico                                 |
| `-q`              | Modo quieto (menos output)                                |

## Workflow WPA/WPA2

### 1. Ativar modo monitor
```json
{
  "tool": "aircrack-ng",
  "target": "",
  "options": "airmon-ng start wlan0"
}
```

### 2. Capturar handshake
```bash
airodump-ng --bssid AA:BB:CC:DD:EE:FF -c 6 -w /root/captures/target wlan0mon
```

### 3. Forçar deauth (acelerar captura)
```bash
aireplay-ng -0 5 -a AA:BB:CC:DD:EE:FF wlan0mon
```

### 4. Crack do handshake
```json
{
  "tool": "aircrack-ng",
  "target": "/root/captures/target-01.cap",
  "options": "-w /root/wordlists/rockyou.txt -b AA:BB:CC:DD:EE:FF /root/captures/target-01.cap"
}
```

## Exemplos

### Crack WPA com wordlist
```json
{
  "tool": "aircrack-ng",
  "target": "/root/captures/handshake.cap",
  "options": "-w /root/wordlists/rockyou.txt -b AA:BB:CC:DD:EE:FF /root/captures/handshake.cap"
}
```

### Crack WEP
```json
{
  "tool": "aircrack-ng",
  "target": "/root/captures/wep.ivs",
  "options": "/root/captures/wep.ivs"
}
```

## OPSEC

- Modo monitor é detectável por alguns IDS sem fio
- Pacotes deauth são detectados por WIDS e alguns drivers
- Capture apenas em redes autorizadas
- Use `-q` para reduzir output em automações

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Chave encontrada: `KEY FOUND! [ senha ]`
