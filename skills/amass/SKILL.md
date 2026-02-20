---
name: "amass"
description: "Mapeamento avançado de superfície de ataque com enumeração ativa e passiva de subdomínios, coleta de inteligência de rede, suporte a múltiplos subcomandos (enum, intel, viz, track, db) e integração com dezenas de fontes de dados. Ferramenta referência para reconhecimento profundo em pentests e bug bounty."
---

# amass

## Objetivo

O amass é a ferramenta mais completa para mapeamento de superfície de ataque de uma organização. Vai além da simples enumeração de subdomínios: correlaciona ASNs, blocos CIDR, certificados TLS, registros WHOIS e dados de múltiplas fontes OSINT para construir um grafo de relacionamento da infraestrutura do alvo.

Casos de uso principais:
- Enumeração profunda de subdomínios com correlação de infraestrutura
- Descoberta de ranges de IP e ASNs associados ao alvo
- Mapeamento de toda a presença de rede de uma organização
- Força bruta DNS com wordlists customizadas
- Monitoramento contínuo de mudanças na superfície de ataque
- Geração de grafos de relacionamento para análise visual

## Endpoint

```
POST /api/recon/amass
```

## Requer target

Sim. O campo `domain` deve conter o domínio raiz. Para o subcomando `intel`, pode-se usar ASN ou range de IP.

## Parâmetros

| Parâmetro  | Tipo   | Obrigatório | Descrição                                                                      |
|------------|--------|-------------|--------------------------------------------------------------------------------|
| `domain`   | string | Sim         | Domínio alvo para enumeração (ex: `example.com`)                               |
| `options`  | string | Não         | Subcomando e flags CLI (ex: `enum -passive`, `intel -org "Empresa"`)           |

## Flags Importantes

### Subcomando `enum` (enumeração principal)

| Flag           | Argumento       | Descrição                                                                 |
|----------------|-----------------|---------------------------------------------------------------------------|
| `-d`           | `domínio`       | Domínio alvo único                                                        |
| `-df`          | `arquivo`       | Arquivo com lista de domínios, um por linha                               |
| `-o`           | `arquivo`       | Arquivo de saída com subdomínios encontrados                              |
| `-json`        | `arquivo`       | Saída completa em JSON com metadados (IPs, fontes, ASNs)                  |
| `-passive`     | —               | Apenas fontes passivas, sem interação com o alvo                          |
| `-active`      | —               | Modo ativo: resolve DNS, faz zone transfer, certificate grabbing          |
| `-brute`       | —               | Habilita força bruta DNS com wordlist                                     |
| `-w`           | `wordlist`      | Wordlist para força bruta DNS (padrão: lista interna)                     |
| `-r`           | `resolvers`     | Resolvers DNS customizados separados por vírgula                          |
| `-rf`          | `arquivo`       | Arquivo com lista de resolvers DNS                                        |
| `-p`           | `proxies`       | Proxies para rotação (ex: socks5://127.0.0.1:9050)                        |
| `-timeout`     | `N`             | Timeout global em minutos                                                 |
| `-max-depth`   | `N`             | Profundidade máxima de enumeração recursiva                               |
| `-config`      | `arquivo`       | Arquivo de configuração com chaves de API (`config.ini`)                  |
| `-ip`          | —               | Inclui endereços IP resolvidos na saída                                   |
| `-src`         | —               | Inclui a fonte de dados de cada subdomínio na saída                       |

### Subcomando `intel` (coleta de inteligência)

| Flag      | Argumento  | Descrição                                                            |
|-----------|------------|----------------------------------------------------------------------|
| `-org`    | `"nome"`   | Busca por nome de organização para descobrir ASNs e ranges de IP     |
| `-asn`    | `N`        | Enumera domínios associados a um número de ASN específico            |
| `-cidr`   | `CIDR`     | Descobre domínios dentro de um range CIDR                            |
| `-whois`  | —          | Usa dados WHOIS reverso para ampliar a cobertura                     |

## Exemplos

**Caso 1 — Enumeração passiva básica (segura, sem contato com o alvo):**
```json
{
  "domain": "example.com",
  "options": "enum -passive -d example.com -silent"
}
```

**Caso 2 — Enumeração ativa com IPs e fonte de dados incluídos:**
```json
{
  "domain": "hackerone.com",
  "options": "enum -active -d hackerone.com -ip -src -o /tmp/amass_hackerone.txt"
}
```

**Caso 3 — Força bruta DNS com wordlist customizada e múltiplos resolvers:**
```json
{
  "domain": "bugcrowd.com",
  "options": "enum -brute -d bugcrowd.com -w /usr/share/wordlists/subdomains.txt -rf /tmp/resolvers.txt -o /tmp/amass_brute.txt"
}
```

**Caso 4 — Inteligência por organização para descobrir toda a infraestrutura:**
```json
{
  "domain": "google.com",
  "options": "intel -org \"Google LLC\" -whois"
}
```

**Caso 5 — Enumeração completa com saída JSON para análise posterior:**
```json
{
  "domain": "tesla.com",
  "options": "enum -active -d tesla.com -json /tmp/amass_tesla.json -ip -src -timeout 60"
}
```

## OPSEC

- O modo `-passive` é completamente furtivo — não gera tráfego ao alvo. Sempre inicie por aqui.
- O modo `-active` realiza consultas DNS diretas, zone transfer tentatives e certificate grabbing, o que pode ser registrado pelos sistemas do alvo. Use com cautela.
- `-brute` gera volume alto de consultas DNS — utilize resolvers externos (`-r 8.8.8.8,1.1.1.1`) para não revelar sua origem.
- O amass armazena resultados em banco de dados local (`~/.config/amass/`); use `amass db` para consultas históricas sem re-executar a enumeração.
- Para anonimato, combine com `-p socks5://127.0.0.1:9050` roteando pelo Tor.
- Chaves de API no `config.ini` são essenciais: sem elas, fontes como Shodan, Censys, SecurityTrails e VirusTotal não são consultadas.
- O amass pode ser lento em enumerações profundas — defina `-timeout` adequadamente para não bloquear o pipeline.

## Saída

A API retorna um objeto JSON com os seguintes campos:

| Campo       | Tipo    | Descrição                                                               |
|-------------|---------|-------------------------------------------------------------------------|
| `success`   | boolean | Indica se a execução foi bem-sucedida                                   |
| `stdout`    | string  | Subdomínios encontrados, com IPs e fontes se `-ip -src` usado           |
| `stderr`    | string  | Logs e avisos de execução                                               |
| `report`    | object  | Sumário com contagem de subdomínios, IPs únicos e fontes utilizadas     |
| `artifacts` | array   | Arquivos gerados (JSON, txt de saída, banco de dados)                   |

Exemplo de stdout com `-ip -src`:
```
api.example.com (Shodan) [1.2.3.4]
mail.example.com (CertSpotter) [5.6.7.8]
dev.example.com (crt.sh) [9.10.11.12]
```
