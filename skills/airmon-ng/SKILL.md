---
name: "airmon-ng"
description: "Ferramenta para ativar e desativar o modo monitor em interfaces wireless. Parte da suíte aircrack-ng. Essencial como primeiro passo em qualquer auditoria WiFi — coloca a interface em modo promíscuo para captura de pacotes e injeção."
---

# airmon-ng

## Objetivo

- Ativar modo monitor em interfaces wireless (wlan0 → wlan0mon)
- Desativar modo monitor e restaurar modo gerenciado
- Identificar processos que interferem no modo monitor (NetworkManager, wpa_supplicant)
- Matar processos interferentes antes de ativar modo monitor
- Listar interfaces wireless e seus drivers

## Endpoint

- /api/tools/run (tool: "airmon-ng")
- /api/tools/dry-run (tool: "airmon-ng")

## Requer target

- não (interface wireless especificada nas options)

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                         |
|-----------|--------|-------------|---------------------------------------------------|
| options   | string | sim         | Comando: `start wlan0`, `stop wlan0mon`, `check kill` |

## Comandos Disponíveis

| Comando              | Descrição                                                         |
|----------------------|-------------------------------------------------------------------|
| `start wlan0`        | Ativa modo monitor na interface wlan0 (cria wlan0mon)            |
| `stop wlan0mon`      | Desativa modo monitor e restaura modo gerenciado                  |
| `check`              | Lista processos que podem interferir no modo monitor              |
| `check kill`         | Mata processos interferentes (NetworkManager, dhclient, etc.)     |
| `start wlan0 6`      | Ativa modo monitor fixando no canal 6                             |
| (sem args)           | Lista todas as interfaces wireless e informações de driver        |

## Exemplos

### Ativar modo monitor

```json
{
  "tool": "airmon-ng",
  "options": "start wlan0"
}
```

### Verificar e matar processos interferentes antes

```json
{
  "tool": "airmon-ng",
  "options": "check kill"
}
```

### Ativar modo monitor em canal específico

```json
{
  "tool": "airmon-ng",
  "options": "start wlan0 6"
}
```

### Desativar modo monitor

```json
{
  "tool": "airmon-ng",
  "options": "stop wlan0mon"
}
```

### Listar interfaces

```json
{
  "tool": "airmon-ng",
  "options": ""
}
```

## Workflow WiFi — Etapa 1

```
1. Verificar e matar processos interferentes:
   airmon-ng check kill
2. Ativar modo monitor:
   airmon-ng start wlan0
3. Confirmar interface criada (wlan0mon):
   iwconfig wlan0mon
4. Prosseguir com airodump-ng para captura
5. Ao finalizar, restaurar:
   airmon-ng stop wlan0mon
```

## OPSEC

- Ativar modo monitor desconecta a interface do AP atual
- O sistema perde conectividade WiFi durante o teste
- `check kill` encerra NetworkManager — pode afetar VPNs e outras conexões
- Modo monitor é detectável por alguns WIDS (Wireless Intrusion Detection Systems)
- Sempre restaure a interface após o teste (`stop wlan0mon`)
- Alguns drivers não suportam modo monitor (chipsets comuns: Alfa AWUS036ACH, RTL8812AU)

## Saída

- JSON com campos: `success`, `stdout`, `stderr`, `report`, `artifacts`
- Saída inclui nome da interface monitor criada (ex: `wlan0mon`)
- Informa PHY, driver e chipset da interface
