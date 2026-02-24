# QUICK START GUIDE

# Kali Linux MCP Pentest Environment

## 🚀 Início Rápido (5 minutos)

### 1. Build e Start

```bash
# Build da imagem
docker-compose build

# Iniciar o container
docker-compose up -d

# Verificar se está rodando
docker ps | grep cleo-kali-mcp
```

### 2. Acesso

```bash
# Entrar no container
docker exec -it cleo-kali-mcp /bin/bash

# Ou usar o Makefile
make shell
```

### 3. Primeiro Teste

#### Teste via API (do host)

```bash
# Health check
curl http://localhost:3000/health

# Listar ferramentas disponíveis
curl http://localhost:3000/api/tools/list | jq

# Executar ferramentas adicionais (rota genérica)
curl -X POST http://localhost:3000/api/tools/run \
  -H "Content-Type: application/json" \
  -d '{"tool":"whatweb","target":"http://example.com","options":""}'
```

#### Teste direto (dentro do container)

```bash
# Nmap rápido
nmap -F scanme.nmap.org

# Verificar wordlists
ls -lh /root/wordlists/
```

## 📝 Primeiros Comandos

### Reconhecimento Automático

```bash
# Dentro do container
/root/scripts/full_recon.sh 192.168.1.0/24

# Via Makefile (do host)
make recon TARGET=192.168.1.0/24
```

### Brute Force SSH

```bash
# Dentro do container
/root/scripts/auto_bruteforce.sh 192.168.1.100 ssh -u root

# Via Makefile (do host)
make bruteforce TARGET=192.168.1.100 SERVICE=ssh USER=root
```

### Scan com Python

```bash
# Dentro do container
python3 /root/scripts/pentest_automation.py -t 192.168.1.100
```

## 🔥 Comandos Úteis

### Gerenciamento Docker

```bash
make build          # Build da imagem
make up             # Iniciar container
make down           # Parar container
make restart        # Reiniciar
make logs           # Ver logs
make shell          # Acessar shell
make stats          # Estatísticas de recursos
```

### Ferramentas Principais

```bash
# Nmap
nmap -sV -sC 192.168.1.100

# Masscan
masscan 192.168.1.0/24 -p1-65535 --rate=1000

# Hydra (SSH)
hydra -l root -P /root/wordlists/rockyou.txt ssh://192.168.1.100

# SQLMap
sqlmap -u "http://site.com/page.php?id=1" --batch

# Nikto
nikto -h http://192.168.1.100

# Amass
amass enum -d example.com

# Subfinder
subfinder -d example.com

# httpx
httpx -u https://example.com

# nuclei
nuclei -u https://example.com

# ffuf
ffuf -u https://example.com/FUZZ -w /usr/share/wordlists/dirb/common.txt
```

## 📊 Verificação de Instalação

### Checklist

- [ ] Container rodando: `docker ps | grep kali-mcp`
- [ ] MCP Server respondendo: `curl http://localhost:3000/health`
- [ ] Shell acessível: `make shell`
- [ ] Nmap instalado: `docker exec cleo-kali-mcp nmap --version`
- [ ] Wordlists disponíveis: `docker exec cleo-kali-mcp ls /root/wordlists/`

### Troubleshooting Rápido

**Container não inicia:**

```bash
docker-compose logs -f
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**MCP Server não responde:**

```bash
docker exec cleo-kali-mcp ps aux | grep node
docker restart cleo-kali-mcp
```

**Wordlists não encontradas:**

```bash
make wordlists
```

## 🎯 Workflows Comuns

### 1. Scan de Rede Completo

```bash
# Reconhecimento
make recon TARGET=192.168.1.0/24

# Ver relatório
docker exec cleo-kali-mcp cat /root/reports/*/SUMMARY_REPORT.txt
```

### 2. Teste de Aplicação Web

```bash
# Via API (do host)
curl -X POST http://localhost:3000/api/web/nikto \
  -H "Content-Type: application/json" \
  -d '{"host":"example.com","port":80}'

curl -X POST http://localhost:3000/api/web/gobuster \
  -H "Content-Type: application/json" \
  -d '{"url":"http://example.com","extensions":"php,html"}'

curl -X POST http://localhost:3000/api/web/nuclei \
  -H "Content-Type: application/json" \
  -d '{"target":"https://example.com"}'

curl -X POST http://localhost:3000/api/web/ffuf \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com/FUZZ","wordlist":"/usr/share/wordlists/dirb/common.txt"}'
```

### 3. Brute Force Multi-Serviço

```bash
# SSH
make bruteforce TARGET=192.168.1.100 SERVICE=ssh USER=admin

# FTP
make bruteforce TARGET=192.168.1.100 SERVICE=ftp USER=anonymous

# MySQL
docker exec cleo-kali-mcp /root/scripts/auto_bruteforce.sh \
  192.168.1.100 mysql -u root -s 3306
```

### 4. Recon e Bug Bounty (exemplos rápidos)

```bash
curl -X POST http://localhost:3000/api/recon/amass \
  -H "Content-Type: application/json" \
  -d '{"domain":"example.com"}'

curl -X POST http://localhost:3000/api/recon/subfinder \
  -H "Content-Type: application/json" \
  -d '{"domain":"example.com"}'

curl -X POST http://localhost:3000/api/tools/run \
  -H "Content-Type: application/json" \
  -d '{"tool":"waybackurls","target":"example.com","options":""}'
```

## 📁 Localização de Arquivos

### No Container

```
/root/reports/          # Relatórios gerados
/root/scripts/          # Scripts de automação
/root/wordlists/        # Wordlists
/root/nmap-results/     # Resultados do nmap
/opt/mcp-server/        # Servidor MCP
```

### No Host (volumes)

```
./reports/              # Persistente
./scripts/              # Persistente
./wordlists/            # Persistente
./nmap-results/         # Persistente
```

## 🔐 Segurança

### ⚠️ IMPORTANTE

- Use apenas em ambientes autorizados
- Sempre obtenha permissão por escrito
- Execute em redes isoladas
- Mantenha logs de todas as atividades

### Boas Práticas

1. Configure `.env` com senhas fortes
2. Limite recursos do container
3. Use network bridge (não host)
4. Faça backup regular dos reports
5. Revise logs regularmente

## 📚 Próximos Passos

1. **Customize Scripts**: Edite `/root/scripts/` para suas necessidades
2. **Configure Wordlists**: Adicione suas próprias em `./wordlists/`
3. **Explore API**: Leia `README.md` para todos os endpoints
4. **Automatize**: Use Python client em `scripts/mcp_client.py`
5. **Integre**: Conecte com suas ferramentas de CI/CD

## 🆘 Precisa de Ajuda?

```bash
# Ver documentação completa
cat README.md

# Ver comandos do Makefile
make help

# Ver exemplos de API
cat scripts/mcp_client.py

# Logs detalhados
make logs
```

## 🎓 Recursos de Aprendizado

- Kali Tools: https://www.kali.org/tools/
- Nmap: https://nmap.org/book/
- Metasploit: https://docs.metasploit.com/
- OWASP: https://owasp.org/

---

**Happy Hacking! 🎯**

Criado por Thierry Braga
Information Security Analyst @ Oi S.A.
