# Ferramentas e Integração ZeroClaw

Este documento descreve as ferramentas disponíveis no ambiente Kali MCP, seus endpoints de API e a integração com o runtime ZeroClaw.

## 🔗 Integração ZeroClaw (OpenClaw)

O ambiente MCP Server atua como um agente conectado ao ecossistema ZeroClaw, permitindo orquestração remota e execução segura de tarefas de segurança.

### Arquitetura de Conexão
- **Identidade do Dispositivo**: O servidor gera automaticamente um par de chaves Ed25519 (`/tmp/openclaw-device-identity.json`) para autenticação segura.
- **Gateway**: Conecta-se a um Gateway ZeroClaw via HTTP ou WebSocket.
- **Registro & Heartbeat**: O servidor se registra automaticamente e envia pulsos de saúde (heartbeats) periódicos.

### Variáveis de Configuração
| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `OPENCLAW_GATEWAY_URL` | URL do Gateway ZeroClaw | (vazio) |
| `OPENCLAW_GATEWAY_TOKEN` | Token de autenticação (opcional) | (vazio) |
| `OPENCLAW_DEVICE_IDENTITY_PATH` | Caminho do arquivo de identidade | `/tmp/openclaw-device-identity.json` |

---

## 🛠️ Endpoints de Ferramentas

O servidor expõe APIs RESTful para execução de ferramentas. Existem endpoints específicos para ferramentas complexas e um endpoint genérico para ferramentas CLI simples.

### Endpoints Genéricos

Para ferramentas que não possuem endpoint dedicado, utilize o runner genérico.

**Executar Ferramenta:**
`POST /api/tools/run`
```json
{
  "tool": "whatweb",
  "target": "example.com",
  "options": "--no-errors"
}
```

**Simular Execução (Dry Run):**
`POST /api/tools/dry-run`
(Retorna o comando que seria executado sem rodá-lo)

**Pipeline (Múltiplos Passos):**
`POST /api/tools/pipeline`
```json
{
  "steps": [
    { "tool": "subfinder", "target": "example.com", "options": "-silent" },
    { "tool": "httpx", "target": "example.com", "options": "-title" }
  ]
}
```

---

### 🕵️‍♂️ Pesquisa & Automação Avançada

Ferramentas de IA, pesquisa profunda e automação de CAPTCHA.

| Recurso | Endpoint | Descrição | Configuração Necessária |
|---------|----------|-----------|-------------------------|
| **Caipora RAG** | `/api/caipora/chat` | Assistente de IA com acesso à base de conhecimento Caipora. Payload: `{"query": "como usar nmap?"}` | Arquivo `caipora-tools.json` |
| **Perplexity** | `/api/research/deep` | Pesquisa profunda na web via Perplexity API com citações. Payload: `{"query": "cve recente wordpress"}` | `PERPLEXITY_API_KEY` |
| **Tor / Onion** | `/api/onion/search` | Busca na rede Onion (Dark Web) via DuckDuckGo Onion. Payload: `{"query": "hidden services"}` | Serviço Tor ativo (auto-iniciado) |
| **2Captcha** | `/api/tools/run` | Resolução de CAPTCHAs. Ferramenta: `2captcha`. Payload: `{"tool": "2captcha", "options": "image 'url'"}` | `TWOCAPTCHA_API_KEY` |

---

### 🔍 Scanning & Reconhecimento

| Ferramenta | Endpoint | Payload Exemplo |
|------------|----------|-----------------|
| **Nmap** | `/api/scan/nmap` | `{"target": "10.0.0.1", "options": "-sV -sC"}` |
| **Masscan** | `/api/scan/masscan` | `{"target": "10.0.0.0/24", "ports": "80,443", "rate": "1000"}` |
| **Amass** | `/api/recon/amass` | `{"domain": "example.com", "options": "enum"}` |
| **Subfinder** | `/api/recon/subfinder` | `{"domain": "example.com"}` |
| **Unicornscan** | `/api/tools/run` | `{"tool": "unicornscan", "target": "10.0.0.1", "options": "-mU"}` |
| **Amap** | `/api/tools/run` | `{"tool": "amap", "target": "10.0.0.1", "options": "-bqv 80"}` |
| **Assetfinder** | `/api/tools/run` | `{"tool": "assetfinder", "target": "example.com", "options": "--subs-only"}` |
| **Cloudbrute** | `/api/tools/run` | `{"tool": "cloudbrute", "target": "example.com", "options": "-k keyword"}` |
| **Dmitry** | `/api/tools/run` | `{"tool": "dmitry", "target": "example.com", "options": "-winse"}` |
| **DNSRecon** | `/api/tools/run` | `{"tool": "dnsrecon", "target": "example.com", "options": "-t std"}` |
| **Enum4linux** | `/api/tools/run` | `{"tool": "enum4linux", "target": "10.0.0.1", "options": "-a"}` |
| **Gau** | `/api/tools/run` | `{"tool": "gau", "target": "example.com", "options": ""}` |
| **Ike-scan** | `/api/tools/run` | `{"tool": "ike-scan", "target": "10.0.0.1", "options": "-M"}` |
| **Lbd** | `/api/tools/run` | `{"tool": "lbd", "target": "example.com", "options": ""}` |
| **MassDNS** | `/api/tools/run` | `{"tool": "massdns", "target": "lista.txt", "options": "-r resolvers.txt"}` |
| **Recon-ng** | `/api/tools/run` | `{"tool": "recon-ng", "options": "-r script.rc"}` |
| **Smtp-user-enum** | `/api/tools/run` | `{"tool": "smtp-user-enum", "target": "10.0.0.1", "options": "-M VRFY -U users.txt"}` |
| **Snmp-check** | `/api/tools/run` | `{"tool": "snmp-check", "target": "10.0.0.1", "options": "-c public"}` |
| **Spiderfoot** | `/api/tools/run` | `{"tool": "spiderfoot", "target": "example.com", "options": "-m s3bucket"}` |
| **SSLScan** | `/api/tools/run` | `{"tool": "sslscan", "target": "example.com", "options": ""}` |
| **SSLStrip** | `/api/tools/run` | `{"tool": "sslstrip", "options": "-l 8080"}` |
| **Sublist3r** | `/api/tools/run` | `{"tool": "sublist3r", "target": "example.com", "options": ""}` |
| **TheHarvester** | `/api/tools/run` | `{"tool": "theharvester", "target": "example.com", "options": "-b all"}` |
| **Waybackurls** | `/api/tools/run` | `{"tool": "waybackurls", "target": "example.com", "options": ""}` |
| **WhatWeb** | `/api/tools/run` | `{"tool": "whatweb", "target": "example.com", "options": "-a 3"}` |

### 🌐 Segurança Web

| Ferramenta | Endpoint | Payload Exemplo |
|------------|----------|-----------------|
| **Nikto** | `/api/web/nikto` | `{"host": "example.com", "port": 80, "ssl": false}` |
| **SQLMap** | `/api/web/sqlmap` | `{"url": "http://site.com/id=1", "options": "--batch --dbs"}` |
| **WPScan** | `/api/web/wpscan` | `{"url": "http://blog.com", "options": "--enumerate u"}` |
| **Gobuster** | `/api/web/gobuster` | `{"url": "http://site.com", "mode": "dir", "wordlist": "common.txt"}` |
| **Dirb** | `/api/web/dirb` | `{"url": "http://site.com", "wordlist": "common.txt"}` |
| **Nuclei** | `/api/web/nuclei` | `{"target": "http://site.com", "options": "-t cves/"}` |
| **FFuf** | `/api/web/ffuf` | `{"url": "http://site.com/FUZZ", "options": "-mc 200"}` |
| **Feroxbuster**| `/api/web/feroxbuster`| `{"url": "http://site.com", "options": "--depth 2"}` |
| **HTTPX** | `/api/web/httpx` | `{"target": "subdomains.txt", "options": "-title -status-code"}` |
| **NoSQLMap** | `/api/web/nosqlmap` | `{"url": "http://site.com", "options": ""}` |
| **Arachni** | `/api/tools/run` | `{"tool": "arachni", "target": "http://site.com", "options": ""}` |
| **Arjun** | `/api/tools/run` | `{"tool": "arjun", "target": "http://site.com", "options": "--get"}` |
| **CMSmap** | `/api/tools/run` | `{"tool": "cmsmap", "target": "http://site.com", "options": ""}` |
| **Commix** | `/api/web/commix` | `{"url": "http://site.com/vuln.php?id=1", "options": "--batch"}` |
| **Dalfox** | `/api/tools/run` | `{"tool": "dalfox", "target": "http://site.com", "options": "url http://site.com"}` |
| **DavTest** | `/api/tools/run` | `{"tool": "davtest", "target": "http://site.com", "options": ""}` |
| **Dirsearch** | `/api/web/dirsearch` | `{"url": "http://site.com", "options": "-e php,html"}` |
| **Droopescan** | `/api/tools/run` | `{"tool": "droopescan", "target": "http://site.com", "options": "scan drupal"}` |
| **JoomScan** | `/api/tools/run` | `{"tool": "joomscan", "target": "http://site.com", "options": ""}` |
| **ParamSpider** | `/api/tools/run` | `{"tool": "paramspider", "target": "example.com", "options": ""}` |
| **Skipfish** | `/api/tools/run` | `{"tool": "skipfish", "target": "http://site.com", "options": "-o /tmp/out"}` |
| **Wafw00f** | `/api/tools/run` | `{"tool": "wafw00f", "target": "http://site.com", "options": ""}` |
| **Weevely** | `/api/tools/run` | `{"tool": "weevely", "options": "generate pass path.php"}` |
| **XSStrike** | `/api/tools/run` | `{"tool": "xsstrike", "target": "http://site.com", "options": "-u http://site.com"}` |

### 🔓 Brute Force & Senhas

| Ferramenta | Endpoint | Payload Exemplo |
|------------|----------|-----------------|
| **Hydra** | `/api/bruteforce/hydra` | `{"target": "10.0.0.1", "service": "ssh", "username": "root", "passlist": "rockyou.txt"}` |
| **Medusa** | `/api/tools/run` | `{"tool": "medusa", "target": "10.0.0.1", "options": "-M ssh -u root -P pass.txt"}` |
| **NCrack** | `/api/tools/run` | `{"tool": "ncrack", "target": "10.0.0.1", "options": "-p 22 --user root"}` |
| **John** | `/api/tools/run` | `{"tool": "john", "target": "hash.txt", "options": "--format=md5"}` |
| **Brutespray** | `/api/tools/run` | `{"tool": "brutespray", "target": "10.0.0.1", "options": "-f nmap.xml"}` |
| **Cewl** | `/api/tools/run` | `{"tool": "cewl", "target": "http://site.com", "options": "-d 2 -w dict.txt"}` |
| **Crunch** | `/api/tools/run` | `{"tool": "crunch", "options": "8 8 abc123"}` |
| **Hashcat** | `/api/tools/run` | `{"tool": "hashcat", "target": "hashes.txt", "options": "-m 0 wordlist.txt"}` |
| **Ophcrack** | `/api/tools/run` | `{"tool": "ophcrack", "options": "-t tables -f hash.txt"}` |

### 📡 Wireless (WiFi)

| Ferramenta | Endpoint | Descrição |
|------------|----------|-----------|
| **Aircrack-ng** | `/api/tools/run` | Suite completa (crack de chaves) |
| **Aireplay-ng** | `/api/tools/run` | Injeção de pacotes |
| **Airodump-ng** | `/api/tools/run` | Captura de pacotes |
| **Wifite** | `/api/tools/run` | Automação de ataque WiFi |
| **Reaver** | `/api/tools/run` | Ataque WPS (Pixie Dust/Pin) |
| **Airgeddon** | `/api/tools/run` | Script multi-uso para auditoria wireless |
| **Airmon-ng** | `/api/tools/run` | Gestão de modo monitor |
| **Bully** | `/api/tools/run` | Ataque WPS (alternativa ao Reaver) |
| **Fern-wifi-cracker** | `/api/tools/run` | GUI/Toolkit para auditoria wireless |
| **Kismet** | `/api/tools/run` | Sniffer e IDS wireless |
| **MDK4** | `/api/tools/run` | Ferramenta de injeção de pacotes WiFi |
| **Pixiewps** | `/api/tools/run` | Ataque offline WPS Pixie Dust |
| **Wifi-pumpkin3** | `/api/tools/run` | Framework para Rogue AP |

### 💥 Exploração & Pós-Exploração

| Ferramenta | Endpoint | Descrição |
|------------|----------|-----------|
| **Metasploit** | `/api/exploit/msfconsole` | Framework de exploração completo |
| **Msfvenom** | `/api/tools/run` | Gerador de payloads |
| **BeEF** | `/api/tools/run` | Browser Exploitation Framework |
| **Bettercap** | `/api/tools/run` | MITM e manipulação de rede |
| **CrackMapExec** | `/api/tools/run` | Pós-exploração em redes AD/SMB |
| **Impacket** | `/api/tools/run` | Coleção de scripts Python para protocolos de rede |
| **Linux-exploit-suggester** | `/api/tools/run` | Sugere exploits para Linux baseados em kernel |
| **Responder** | `/api/tools/run` | Envenenamento LLMNR/NBT-NS |
| **Routersploit** | `/api/tools/run` | Framework de exploração para roteadores/IoT |
| **SET** | `/api/tools/run` | Social-Engineer Toolkit |
| **Windows-exploit-suggester** | `/api/tools/run` | Sugere exploits para Windows baseados em systeminfo |
| **Yersinia** | `/api/tools/run` | Ataques a protocolos de rede L2 |

### 🔍 Forense & Engenharia Reversa

| Ferramenta | Endpoint | Descrição |
|------------|----------|-----------|
| **Apktool** | `/api/tools/run` | Engenharia reversa de apps Android |
| **Autopsy** | `/api/tools/run` | Plataforma forense digital |
| **Binwalk** | `/api/tools/run` | Análise de firmware e extração |
| **Dex2jar** | `/api/tools/run` | Converte .dex para .jar |
| **Exiftool** | `/api/tools/run` | Leitura e edição de metadados |
| **Foremost** | `/api/tools/run` | Recuperação de arquivos (file carving) |
| **Ghidra** | `/api/tools/run` | Suite de engenharia reversa da NSA |
| **Radare2** | `/api/tools/run` | Framework de engenharia reversa tipo UNIX |
| **Strings** | `/api/tools/run` | Extrai strings imprimíveis de binários |
| **Volatility** | `/api/tools/run` | Forense de memória RAM |

### 🏢 Rede & Active Directory

| Ferramenta | Endpoint | Descrição |
|------------|----------|-----------|
| **Bloodhound** | `/api/tools/run` | Mapeamento de relações de confiança em AD |
| **LDAPDomainDump** | `/api/tools/run` | Dump de informações via LDAP |
| **MITMf** | `/api/tools/run` | Framework para ataques Man-In-The-Middle |
| **Driftnet** | `/api/tools/run` | Captura imagens de tráfego de rede |
