---
name: "subfinder"
description: "Descoberta passiva de subdomínios via múltiplas APIs e fontes OSINT. Ferramenta Go de alta performance que consulta fontes como crt.sh, HackerTarget, ThreatCrowd, VirusTotal, Shodan, Censys e dezenas de outras para mapear a superfície de ataque de um domínio sem interação direta com o alvo."
---

# subfinder

## Objetivo

O subfinder realiza enumeração passiva de subdomínios consultando diversas fontes de inteligência pública (OSINT) e APIs externas. É ideal para a fase de reconhecimento porque não gera tráfego direto ao alvo, reduzindo o risco de detecção. Deve ser a primeira ferramenta executada em qualquer recon de subdomínios.

Casos de uso principais:
- Mapear a superfície de ataque antes de qualquer interação ativa
- Descobrir ativos esquecidos ou expostos inadvertidamente
- Alimentar pipelines de recon (saída para massdns, httprobe, nuclei)
- Monitoramento contínuo de novos subdomínios de um alvo
- Coleta de inteligência em bug bounty e pentests externos

## Endpoint

```
POST /api/recon/subfinder
```

## Requer target

Sim. O campo `domain` é obrigatório e deve conter o domínio raiz a ser enumerado (ex: `example.com`).

## Parâmetros

| Parâmetro | Tipo   | Obrigatório | Descrição                                                                 |
|-----------|--------|-------------|---------------------------------------------------------------------------|
| `domain`  | string | Sim         | Domínio alvo para enumeração de subdomínios (ex: `example.com`)          |
| `options` | string | Não         | Flags CLI adicionais passadas diretamente ao subfinder                    |

## Flags Importantes

| Flag              | Argumento       | Descrição                                                                 |
|-------------------|-----------------|---------------------------------------------------------------------------|
| `-d`              | `domínio`       | Domínio alvo único                                                        |
| `-dL`             | `arquivo`       | Arquivo com lista de domínios, um por linha                               |
| `-o`              | `arquivo`       | Arquivo de saída com os subdomínios encontrados                           |
| `-oJ`             | `arquivo`       | Saída em formato JSON com metadados (fonte, domínio)                      |
| `-silent`         | —               | Suprime banners e logs, exibe apenas subdomínios                          |
| `-t`              | `N`             | Número de threads concorrentes (padrão: 10)                               |
| `-timeout`        | `N`             | Timeout em segundos por fonte (padrão: 30)                                |
| `-r`              | `resolvers`     | Resolvers DNS customizados separados por vírgula                          |
| `-nW`             | —               | Remove subdomínios com wildcard DNS                                       |
| `-all`            | —               | Usa todas as fontes disponíveis, incluindo lentas                         |
| `-cs`             | —               | Inclui a fonte de origem em cada subdomínio encontrado                    |
| `-v`              | —               | Modo verbose com detalhes de execução por fonte                           |
| `-active`         | —               | Verifica se os subdomínios encontrados estão ativos via DNS               |
| `-es`             | `fonte1,fonte2` | Exclui fontes específicas (ex: `-es shodan,fofa`)                         |
| `-config`         | `arquivo`       | Arquivo de configuração com chaves de API (`~/.config/subfinder/config.yaml`) |

## Exemplos

**Caso 1 — Enumeração básica passiva de um domínio:**
```json
{
  "domain": "example.com",
  "options": "-silent"
}
```

**Caso 2 — Enumeração completa com todas as fontes e saída JSON:**
```json
{
  "domain": "hackerone.com",
  "options": "-all -oJ /tmp/hackerone_subs.json -t 20 -timeout 60"
}
```

**Caso 3 — Incluindo a fonte de cada subdomínio para rastreabilidade:**
```json
{
  "domain": "bugcrowd.com",
  "options": "-cs -silent -o /tmp/bugcrowd_subs.txt"
}
```

**Caso 4 — Modo ativo para validar subdomínios encontrados com remoção de wildcards:**
```json
{
  "domain": "tesla.com",
  "options": "-active -nW -t 30 -silent"
}
```

**Caso 5 — Excluindo fontes ruidosas e usando resolvers customizados:**
```json
{
  "domain": "uber.com",
  "options": "-es shodan,fofa -r 8.8.8.8,1.1.1.1 -silent -o /tmp/uber_subs.txt"
}
```

## OPSEC

- O subfinder **não faz contato direto com o alvo** — toda a coleta é via fontes OSINT externas, tornando-o seguro para reconhecimento furtivo.
- Evite `-all` em engajamentos onde o tempo é limitado; fontes lentas como Shodan e Censys aumentam a duração.
- Ao usar `-active`, ocorrem consultas DNS que podem aparecer nos logs do servidor DNS alvo — use resolvers de terceiros com `-r`.
- Chaves de API configuradas em `~/.config/subfinder/config.yaml` ampliam significativamente os resultados; sem elas, várias fontes premium ficam indisponíveis.
- Combine a saída com `massdns` para resolver em massa e filtrar apenas subdomínios com resposta válida.
- Em bug bounty, verifique o escopo antes: subdomínios out-of-scope não devem ser testados mesmo que descobertos.

## Saída

A API retorna um objeto JSON com os seguintes campos:

| Campo       | Tipo    | Descrição                                                        |
|-------------|---------|------------------------------------------------------------------|
| `success`   | boolean | Indica se a execução foi bem-sucedida                            |
| `stdout`    | string  | Lista de subdomínios encontrados (um por linha)                  |
| `stderr`    | string  | Mensagens de erro ou avisos da ferramenta                        |
| `report`    | object  | Sumário estruturado com contagem e metadados                     |
| `artifacts` | array   | Arquivos gerados (ex: JSON de saída se `-oJ` foi usado)          |

Exemplo de stdout típico:
```
api.example.com
mail.example.com
dev.example.com
staging.example.com
cdn.example.com
```
