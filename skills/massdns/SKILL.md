---
name: "massdns"
description: "Resolução DNS em massa de alta velocidade capaz de processar milhões de domínios por segundo usando múltiplos resolvers concorrentes. Ferramenta essencial para validar e filtrar listas brutas de subdomínios descobertos por outras ferramentas, identificando quais realmente resolvem para endereços IP válidos."
---

# massdns

## Objetivo

O massdns resolve grandes listas de domínios e subdomínios contra múltiplos resolvers DNS de forma paralela e extremamente eficiente. Seu papel no pipeline de recon é **validar** os subdomínios coletados por ferramentas como subfinder, amass e assetfinder, filtrando os que de fato existem (possuem registro DNS válido) dos que são falsos positivos ou domínios inativos.

Casos de uso principais:
- Resolução em massa de listas de subdomínios para filtrar ativos válidos
- Força bruta DNS de alta velocidade combinando wordlist com domínio alvo
- Identificação de IPs únicos por trás de múltiplos subdomínios (virtualhosting)
- Descoberta de subdomínios com registros DNS incomuns (MX, CNAME, TXT)
- Etapa de validação em pipelines automatizados de bug bounty e recon
- Resolução de grandes listas geradas por alterx ou gotator

## Endpoint

```
POST /api/tools/run
```

## Requer target

Sim. O massdns opera sobre uma lista de domínios fornecida via stdin ou arquivo. O `target` deve ser o arquivo de entrada ou a lista de subdomínios a resolver.

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                                                          |
|-----------|--------|-------------|------------------------------------------------------------------------------------|
| `tool`    | string | Sim         | Deve ser `"massdns"`                                                               |
| `options` | string | Sim         | Flags CLI completas incluindo `-r resolvers.txt` e lista de entrada                |

## Flags Importantes

| Flag              | Argumento      | Descrição                                                                               |
|-------------------|----------------|-----------------------------------------------------------------------------------------|
| `-r`              | `arquivo`      | Arquivo com lista de resolvers DNS, um por linha (obrigatório)                          |
| `-t`              | `tipo`         | Tipo de registro DNS a consultar: `A`, `AAAA`, `CNAME`, `MX`, `TXT`, `NS`              |
| `-o`              | `formato`      | Formato de saída: `S` (simples), `J` (JSON), `L` (lista), `F` (full)                   |
| `-w`              | `arquivo`      | Arquivo de saída para resultados                                                        |
| `--quiet`         | —              | Suprime o contador de progresso (útil em pipelines)                                     |
| `--processes`     | `N`            | Número de processos paralelos (padrão: 1, aumentar melhora throughput)                  |
| `--hashmap-size`  | `N`            | Tamanho do hashmap interno (aumentar reduz colisões em listas grandes)                  |
| `--root-servers`  | —              | Usa servidores raiz em vez de resolvers (mais lento, mais preciso)                      |
| `--verify-ip`     | —              | Verifica se o IP retornado é válido (filtra poisoning)                                  |
| `-s`              | `N`            | Taxa de envio de pacotes por segundo (rate limiting)                                    |

## Formatos de Saída (`-o`)

| Código | Nome     | Descrição                                                                 |
|--------|----------|---------------------------------------------------------------------------|
| `S`    | Simples  | Uma linha por resultado: `domínio. tipo IP`                               |
| `J`    | JSON     | Saída JSON completa com todos os campos da resposta DNS                   |
| `L`    | Lista    | Apenas os domínios que resolveram, sem IPs                                |
| `F`    | Full     | Saída completa incluindo respostas negativas (NXDOMAIN)                   |

## Exemplos

**Caso 1 — Resolução básica de lista de subdomínios para registros A:**
```json
{
  "tool": "massdns",
  "options": "-r /opt/resolvers.txt -t A -o S -w /tmp/massdns_results.txt /tmp/subdomains.txt"
}
```

**Caso 2 — Resolução com saída JSON para análise estruturada:**
```json
{
  "tool": "massdns",
  "options": "-r /opt/resolvers.txt -t A -o J -w /tmp/massdns_json.txt /tmp/subdomains.txt"
}
```

**Caso 3 — Pipeline com subfinder: descobrir e imediatamente resolver:**
```json
{
  "tool": "massdns",
  "options": "-r /opt/resolvers.txt -t A -o S --quiet --processes 4 -w /tmp/resolved.txt /tmp/subfinder_output.txt"
}
```

**Caso 4 — Resolução de múltiplos tipos de registro para análise completa:**
```json
{
  "tool": "massdns",
  "options": "-r /opt/resolvers.txt -t CNAME -o S -w /tmp/cname_results.txt /tmp/subdomains.txt"
}
```

**Caso 5 — Força bruta DNS de alta velocidade com rate limiting:**
```json
{
  "tool": "massdns",
  "options": "-r /opt/resolvers.txt -t A -o S -s 10000 --quiet --hashmap-size 16777216 -w /tmp/brute_results.txt /tmp/bruteforce_list.txt"
}
```

## OPSEC

- O massdns gera volume **muito alto** de consultas DNS — pode ser detectado como ataque DDoS por provedores DNS e IDS/IPS corporativos. Use resolvers públicos de terceiros (`8.8.8.8`, `1.1.1.1`, etc.) nunca os servidores do alvo.
- Use `-s` para limitar a taxa de pacotes por segundo em engajamentos onde o ruído é preocupante. Sem limite, o massdns pode saturar conexões.
- O arquivo de resolvers é crítico: use listas atualizadas de resolvers públicos confiáveis (disponíveis em github.com/janmasarik/resolvers ou similares). Resolvers ruins geram falsos positivos.
- Combine com `--verify-ip` para evitar falsos positivos causados por DNS poisoning ou resolvers maliciosos.
- Em bug bounty, filtre os resultados com `grep -v NXDOMAIN` e extraia apenas os domínios que resolveram antes de passar para etapas ativas.
- Pipeline completo recomendado:
  ```
  subfinder -d alvo.com -silent | massdns -r resolvers.txt -t A -o S --quiet | grep -v "NXDOMAIN" | awk '{print $1}' | sed 's/\.$//' | sort -u > ativos.txt
  ```
- O `--hashmap-size` deve ser aumentado proporcionalmente ao tamanho da lista de entrada para evitar colisões e resultados perdidos em listas com mais de 1 milhão de entradas.

## Saída

A API retorna um objeto JSON com os seguintes campos:

| Campo       | Tipo    | Descrição                                                               |
|-------------|---------|-------------------------------------------------------------------------|
| `success`   | boolean | Indica se a execução foi bem-sucedida                                   |
| `stdout`    | string  | Resultados DNS no formato especificado por `-o`                         |
| `stderr`    | string  | Contadores de progresso e mensagens de erro                             |
| `report`    | object  | Sumário com total resolvido, falhas e IPs únicos identificados          |
| `artifacts` | array   | Arquivo de resultados gerado via `-w`                                   |

Exemplo de stdout no formato `S` (simples):
```
api.example.com. A 93.184.216.34
mail.example.com. A 104.21.45.67
dev.example.com. CNAME dev-internal.example.com.
staging.example.com. A 172.67.128.91
vpn.example.com. A 10.0.0.1
```

Exemplo de stdout no formato `J` (JSON):
```json
{"name":"api.example.com.","type":"A","class":"IN","status":"NOERROR","data":{"answers":[{"ttl":300,"type":"A","name":"api.example.com.","data":"93.184.216.34"}]}}
```
