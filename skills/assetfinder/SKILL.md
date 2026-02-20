---
name: "assetfinder"
description: "Descoberta rápida de subdomínios e assets relacionados a um domínio consultando fontes como crt.sh, Facebook Certificate Transparency, HackerTarget, CertSpotter e outras. Ferramenta leve escrita em Go, ideal para pipelines de recon rápido e combinação com httprobe e aquatone."
---

# assetfinder

## Objetivo

O assetfinder é uma ferramenta minimalista e extremamente rápida para descoberta de subdomínios e assets associados a um domínio. Seu design simples o torna perfeito para integração em pipelines de automação de recon, onde velocidade e baixo overhead são prioritários. Consulta fontes de Certificate Transparency e OSINT sem necessidade de configuração de API keys para uso básico.

Casos de uso principais:
- Reconhecimento rápido inicial de subdomínios de um alvo
- Primeiro estágio em pipelines automatizados de bug bounty
- Coleta de dados de Certificate Transparency para correlação
- Descoberta de assets além de subdomínios (domínios relacionados)
- Integração com httprobe para identificar hosts ativos rapidamente
- Alimentar aquatone para screenshots de ativos web descobertos

## Endpoint

```
POST /api/tools/run
```

## Requer target

Sim. O campo `target` deve conter o domínio raiz a ser investigado (ex: `example.com`).

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                                                        |
|-----------|--------|-------------|----------------------------------------------------------------------------------|
| `tool`    | string | Sim         | Deve ser `"assetfinder"`                                                         |
| `target`  | string | Sim         | Domínio alvo (ex: `example.com`)                                                 |
| `options` | string | Não         | Flags CLI adicionais (principalmente `--subs-only`)                              |

## Flags Importantes

| Flag          | Argumento | Descrição                                                                           |
|---------------|-----------|-------------------------------------------------------------------------------------|
| `--subs-only` | —         | Retorna apenas subdomínios do domínio alvo, filtrando domínios relacionados externos |

Obs: O assetfinder é intencionalmente minimalista. Sem `--subs-only`, ele retorna **todos os assets relacionados**, incluindo domínios de terceiros que apareceram em registros de certificados junto ao alvo. Com `--subs-only`, filtra apenas subdomínios diretos do domínio informado.

## Fontes Consultadas

| Fonte                    | Descrição                                                    |
|--------------------------|--------------------------------------------------------------|
| `crt.sh`                 | Registros de Certificate Transparency do banco público       |
| `Facebook CT`            | Logs de certificados monitorados pelo Facebook               |
| `HackerTarget`           | API pública de inteligência de segurança                     |
| `CertSpotter`            | Monitor de Certificate Transparency da SSLMate              |
| `Riddler`                | Busca em dados de certificados e DNS passivo                 |
| `Wayback Machine`        | URLs históricas com subdomínios do alvo                      |
| `VirusTotal`             | Banco de dados de domínios relacionados a malware e análises |

## Exemplos

**Caso 1 — Descoberta básica de subdomínios somente:**
```json
{
  "tool": "assetfinder",
  "target": "example.com",
  "options": "--subs-only"
}
```

**Caso 2 — Todos os assets relacionados (incluindo domínios de terceiros):**
```json
{
  "tool": "assetfinder",
  "target": "hackerone.com",
  "options": ""
}
```

**Caso 3 — Coleta de subdomínios para pipeline com httprobe:**
```json
{
  "tool": "assetfinder",
  "target": "bugcrowd.com",
  "options": "--subs-only"
}
```

**Caso 4 — Recon de domínio corporativo para correlação de assets:**
```json
{
  "tool": "assetfinder",
  "target": "microsoft.com",
  "options": "--subs-only"
}
```

**Caso 5 — Descoberta ampla sem filtro para mapear ecossistema completo:**
```json
{
  "tool": "assetfinder",
  "target": "shopify.com",
  "options": ""
}
```

## OPSEC

- O assetfinder realiza consultas exclusivamente a fontes externas — **não há contato direto com o alvo**. É completamente passivo e seguro para uso furtivo.
- Sem necessidade de API keys para funcionamento básico, reduzindo a pegada digital em serviços externos.
- A ausência de `--subs-only` pode revelar relações com terceiros que não fazem parte do escopo — analise a saída com atenção antes de agir.
- Para engajamentos de bug bounty, combine com `sort -u` para deduplicar antes de processar com httprobe ou nuclei.
- Pipeline recomendado para recon automatizado:
  ```
  assetfinder --subs-only alvo.com | sort -u | httprobe | tee hosts_vivos.txt | aquatone
  ```
- O assetfinder é mais rápido que subfinder e amass, mas cobre menos fontes. Use-o como primeiro passo rápido, seguido de ferramentas mais completas.
- Resultados do Facebook CT podem incluir subdomínios internos expostos acidentalmente em certificados SAN (Subject Alternative Names).

## Saída

A API retorna um objeto JSON com os seguintes campos:

| Campo       | Tipo    | Descrição                                                               |
|-------------|---------|-------------------------------------------------------------------------|
| `success`   | boolean | Indica se a execução foi bem-sucedida                                   |
| `stdout`    | string  | Lista de subdomínios ou assets encontrados, um por linha                |
| `stderr`    | string  | Mensagens de erro ou avisos da ferramenta                               |
| `report`    | object  | Sumário com contagem de assets descobertos                              |
| `artifacts` | array   | Arquivos gerados (se redirecionamento de saída foi configurado)         |

Exemplo de stdout típico com `--subs-only`:
```
api.example.com
mail.example.com
dev.example.com
staging.example.com
admin.example.com
vpn.example.com
```

Exemplo de stdout sem `--subs-only` (inclui domínios relacionados):
```
api.example.com
mail.example.com
partnersite.com
cdn.thirdparty.net
example.co.uk
```
