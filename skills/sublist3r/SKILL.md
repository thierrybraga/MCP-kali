---
name: "sublist3r"
description: "Enumeração de subdomínios multi-engine via scraping de motores de busca e fontes OSINT. Consulta simultaneamente Google, Bing, Yahoo, Baidu, Ask, Netcraft, VirusTotal, ThreatCrowd, SSL Certificates e PassiveDNS. Suporte a força bruta DNS integrada via subbrute."
---

# sublist3r

## Objetivo

O sublist3r agrega resultados de múltiplos motores de busca e fontes OSINT para enumerar subdomínios de forma abrangente. Sua abordagem multi-engine aumenta a cobertura, pois diferentes fontes indexam partes distintas da internet. O módulo de força bruta integrado (subbrute) permite combinar reconhecimento passivo e ativo em uma única execução.

Casos de uso principais:
- Enumeração de subdomínios combinando múltiplos motores de busca
- Reconhecimento em ambientes onde APIs externas não estão disponíveis
- Força bruta DNS integrada sem necessidade de ferramentas adicionais
- Verificação de quais portas os subdomínios respondem
- Coleta rápida de subdomínios indexados publicamente
- Complemento ao subfinder e amass em fases de recon

## Endpoint

```
POST /api/tools/run
```

## Requer target

Sim. O domínio alvo deve ser passado via flag `-d` no campo `options`.

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                                                         |
|-----------|--------|-------------|-----------------------------------------------------------------------------------|
| `tool`    | string | Sim         | Deve ser `"sublist3r"`                                                            |
| `options` | string | Sim         | Flags CLI incluindo `-d domínio` obrigatoriamente                                 |

## Flags Importantes

| Flag  | Argumento         | Descrição                                                                              |
|-------|-------------------|----------------------------------------------------------------------------------------|
| `-d`  | `domínio`         | Domínio alvo para enumeração (obrigatório)                                             |
| `-b`  | —                 | Habilita força bruta DNS via subbrute (mais lento, maior cobertura)                    |
| `-p`  | `80,443,8080`     | Verifica portas específicas nos subdomínios encontrados                                |
| `-v`  | —                 | Modo verbose com progresso em tempo real por motor de busca                            |
| `-t`  | `N`               | Número de threads para força bruta (padrão: 30)                                        |
| `-e`  | `motor1,motor2`   | Seleciona motores específicos (ex: `-e google,bing,virustotal`)                        |
| `-o`  | `arquivo`         | Salva os subdomínios encontrados em arquivo de saída                                   |

## Motores de Busca e Fontes

| Motor/Fonte    | Tipo        | Descrição                                                          |
|----------------|-------------|--------------------------------------------------------------------|
| `google`       | Search      | Scraping via dorks (`site:dominio.com`) no Google                  |
| `bing`         | Search      | Scraping via dorks no Bing                                         |
| `yahoo`        | Search      | Scraping via dorks no Yahoo Search                                 |
| `baidu`        | Search      | Scraping via dorks no Baidu (útil para alvos com presença na China)|
| `ask`          | Search      | Scraping via dorks no Ask.com                                      |
| `netcraft`     | OSINT       | Banco de dados de certificados e histórico web do Netcraft         |
| `virustotal`   | OSINT       | API pública do VirusTotal para domínios relacionados               |
| `threatcrowd`  | OSINT       | Banco de dados de threat intelligence do ThreatCrowd               |
| `ssl`          | CT Logs     | Registros de Certificate Transparency via SSL certificates         |
| `passivedns`   | DNS Passivo | Dados históricos de resolução DNS passiva                          |

## Exemplos

**Caso 1 — Enumeração básica com todos os motores:**
```json
{
  "tool": "sublist3r",
  "options": "-d example.com"
}
```

**Caso 2 — Enumeração com motores selecionados e saída em arquivo:**
```json
{
  "tool": "sublist3r",
  "options": "-d hackerone.com -e google,bing,virustotal,ssl -o /tmp/sublist3r_hackerone.txt"
}
```

**Caso 3 — Enumeração com força bruta DNS habilitada:**
```json
{
  "tool": "sublist3r",
  "options": "-d bugcrowd.com -b -t 50 -o /tmp/sublist3r_brute.txt"
}
```

**Caso 4 — Verbose com verificação de portas web comuns:**
```json
{
  "tool": "sublist3r",
  "options": "-d target.com -v -p 80,443,8080,8443"
}
```

**Caso 5 — Foco em fontes OSINT sem motores de busca (menor ruído):**
```json
{
  "tool": "sublist3r",
  "options": "-d empresa.com.br -e virustotal,threatcrowd,ssl,passivedns -o /tmp/sublist3r_osint.txt"
}
```

## OPSEC

- O scraping de motores de busca pode acionar CAPTCHAs ou bloqueios de IP, especialmente no Google. Use `-e` para selecionar apenas fontes confiáveis em recon furtivo.
- O modo `-b` (brute force) gera volume considerável de consultas DNS — use resolvers externos e evite em redes monitoradas.
- Fontes como VirusTotal, ThreatCrowd e SSL são passivas e não geram tráfego ao alvo — prefira-as quando OPSEC é crítico.
- O Baidu pode revelar subdomínios não indexados no Google, especialmente de empresas com operações na Ásia.
- Use `-t` para controlar a agressividade da força bruta. Valores acima de 100 podem causar rate limiting nos resolvers.
- Em programas de bug bounty, o sublist3r pode encontrar subdomínios antigos ou esquecidos via PassiveDNS que outras ferramentas não descobrem.
- Combine sublist3r com subfinder para cobertura máxima: as duas ferramentas têm sobreposição parcial mas não total de fontes.

## Saída

A API retorna um objeto JSON com os seguintes campos:

| Campo       | Tipo    | Descrição                                                               |
|-------------|---------|-------------------------------------------------------------------------|
| `success`   | boolean | Indica se a execução foi bem-sucedida                                   |
| `stdout`    | string  | Lista de subdomínios encontrados, um por linha                          |
| `stderr`    | string  | Logs de progresso e erros por motor de busca                            |
| `report`    | object  | Sumário com total de subdomínios e motores que retornaram resultados     |
| `artifacts` | array   | Arquivo de saída gerado se `-o` foi especificado                        |

Exemplo de stdout típico:
```
api.example.com
mail.example.com
dev.example.com
staging.example.com
beta.example.com
admin.example.com
```

Exemplo de stdout com `-p 80,443` (verificação de portas):
```
api.example.com:443
mail.example.com:80
mail.example.com:443
staging.example.com:8080
```
