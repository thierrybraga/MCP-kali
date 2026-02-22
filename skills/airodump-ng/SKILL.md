---
name: "airodump-ng"
description: "Captura de pacotes wireless e sniffing de redes 802.11. Parte da suíte aircrack-ng. Detecta APs e clientes próximos, captura handshakes WPA/WPA2, coleta IVs WEP e salva capturas para análise offline com aircrack-ng. Principal ferramenta de reconhecimento e captura em auditorias WiFi."
---

# airodump-ng

## Objetivo

- Varrer o espectro wireless e listar APs e clientes visíveis
- Capturar handshakes WPA/WPA2 para crack offline
- Coletar IVs WEP para análise estatística
- Salvar capturas em arquivos .cap/.ivs para aircrack-ng
- Monitorar clientes conectados a um AP específico
- Filtrar por BSSID, canal ou banda para focar o ataque

## Endpoint

- /api/tools/run (tool: "airodump-ng")
- /api/tools/dry-run (tool: "airodump-ng")

## Requer target

- não (interface monitor especificada nas options)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                         |
|-----------|--------|-------------|---------------------------------------------------|
| options   | string | sim         | Flags do CLI incluindo interface monitor (wlan0mon) |

## Flags Importantes

| Flag                         | Descrição                                                          |
|------------------------------|---------------------------------------------------------------------|
| `wlan0mon`                   | Interface em modo monitor (último argumento)                       |
| `--bssid AA:BB:CC:DD:EE:FF`  | Filtrar captura para um AP específico                              |
| `-c 6`                       | Fixar no canal 6 (não fazer channel hopping)                       |
| `-w /path/prefix`            | Salvar captura em arquivo (ex: -w /root/cap/target)                |
| `--band bg`                  | Varrer bandas 2.4GHz (b/g) e 5GHz (a)                             |
| `--band a`                   | Varrer apenas 5GHz                                                 |
| `--encrypt WPA`              | Filtrar por tipo de criptografia                                   |
| `--essid "NomeRede"`         | Filtrar por nome da rede                                           |
| `--output-format pcap`       | Formato de saída (pcap, ivs, csv, gps, kismet)                    |
| `--write-interval 1`         | Intervalo de escrita em segundos                                   |

## Arquivos Gerados (com -w prefix)

| Extensão       | Conteúdo                                            |
|----------------|-----------------------------------------------------|
| `prefix-01.cap`| Captura completa de pacotes (inclui handshakes)     |
| `prefix-01.csv`| Lista de APs e clientes em CSV                      |
| `prefix-01.kismet.csv` | Formato Kismet                              |
| `prefix-01.kismet.netxml` | XML do Kismet                            |
| `prefix-01.log.csv` | Log de atividade                               |

## Exemplos

### Varredura geral de APs próximos

```json
{
  "tool": "airodump-ng",
  "options": "wlan0mon"
}
```

### Captura focada em AP específico (para handshake)

```json
{
  "tool": "airodump-ng",
  "options": "--bssid AA:BB:CC:DD:EE:FF -c 6 -w /root/captures/target wlan0mon"
}
```

### Captura em 5GHz

```json
{
  "tool": "airodump-ng",
  "options": "--band a -w /root/captures/scan5g wlan0mon"
}
```

### Filtrar apenas redes WPA2

```json
{
  "tool": "airodump-ng",
  "options": "--encrypt WPA2 -w /root/captures/wpa2 wlan0mon"
}
```

### Captura IVs WEP para crack

```json
{
  "tool": "airodump-ng",
  "options": "--bssid AA:BB:CC:DD:EE:FF -c 11 --output-format ivs -w /root/captures/wep wlan0mon"
}
```

## Workflow Captura de Handshake WPA2

```
1. airmon-ng start wlan0         → Ativar modo monitor
2. airodump-ng wlan0mon          → Identificar BSSID e canal do alvo
3. airodump-ng --bssid TARGET_BSSID -c CANAL -w /root/cap/alvo wlan0mon
4. (Em outro terminal) aireplay-ng -0 5 -a TARGET_BSSID wlan0mon
5. Aguardar "WPA handshake: AA:BB:CC:DD:EE:FF" no topo da tela
6. aircrack-ng -w wordlist.txt /root/cap/alvo-01.cap
```

## OPSEC

- Channel hopping (sem -c) é facilmente detectável em WIDS
- Fixar em um canal (-c) com --bssid é mais discreto
- Capturas salvas contêm dados de clientes — proteger os arquivos .cap
- O nome da rede alvo aparece na tela — use em ambientes privados
- Capturas longas geram arquivos grandes — limitar com `--write-interval`

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- `artifacts`: arquivos .cap, .csv gerados pela captura
- `report`: APs detectados, handshakes capturados, clientes identificados
