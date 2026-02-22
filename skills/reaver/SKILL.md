---
name: "reaver"
description: "Ferramenta de ataque WPS por brute force de PIN. Recupera chave WPA/WPA2 explorando a vulnerabilidade no protocolo WPS (Wi-Fi Protected Setup) em ~4-10 horas."
---

# reaver

## Objetivo

- Brute force do PIN WPS de 8 dígitos para recuperar chave WPA/WPA2
- Exploração da vulnerabilidade de design do WPS (divide PIN em 2 metades)
- Compatível com a maioria dos roteadores domésticos com WPS ativo

## Endpoint

- /api/tools/run (tool: "reaver")

## Requer target

- não (especificado via -b/BSSID nas options)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                 |
|-----------|--------|-------------|-------------------------------------------|
| target    | string | não         | Não utilizado diretamente                 |
| options   | string | sim         | Flags incluindo -i interface e -b BSSID   |

## Flags Importantes

| Flag              | Efeito                                                    |
|-------------------|-----------------------------------------------------------|
| `-i <iface>`      | Interface em modo monitor (ex: wlan0mon)                  |
| `-b <BSSID>`      | BSSID do AP alvo (obrigatório)                            |
| `-c <canal>`      | Canal do AP (1-14)                                        |
| `-v` / `-vv`      | Verbosidade                                               |
| `-d <delay>`      | Delay entre tentativas (segundos)                         |
| `-r <N:M>`        | Esperar M segundos após N tentativas                      |
| `-t <timeout>`    | Timeout de resposta                                       |
| `-p <PIN>`        | Testar PIN específico                                     |
| `-S`              | Usar timeouts menores (mais rápido, menos estável)        |
| `-N`              | Não enviar NACK                                           |
| `-L`              | Ignorar lock WPS                                          |
| `-f`              | Force mode                                                |
| `-s <sessão>`     | Arquivo de sessão para retomar                            |

## Exemplos

### Ataque básico WPS
```json
{
  "tool": "reaver",
  "target": "",
  "options": "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -vv"
}
```

### Com delays para evitar lock
```json
{
  "tool": "reaver",
  "target": "",
  "options": "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -d 15 -r 3:15 -vv"
}
```

### Testar PIN específico (padrão do fabricante)
```json
{
  "tool": "reaver",
  "target": "",
  "options": "-i wlan0mon -b AA:BB:CC:DD:EE:FF -c 6 -p 12345670"
}
```

## OPSEC

- WPS brute force leva ~4-10 horas (11.000 combinações)
- Roteadores modernos bloqueiam WPS após 3-10 tentativas
- Use `-d` alto para evitar lock temporário
- Prefira `bully` ou `wifite` para ataques Pixie Dust
- AVISO: Apenas em redes autorizadas

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- PIN e senha encontrados: `WPS PIN: XXXXXXXX` e `WPA PSK: senha`
