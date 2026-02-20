---
name: "ophcrack"
description: "Ferramenta de cracking de hashes de senha Windows (LM e NTLM) usando rainbow tables pre-computadas. Extremamente rapida para hashes LM e NTLM de senhas alfanumericas curtas pois nao faz brute force - consulta tabelas pre-computadas. Suporta hashes de SAM (pwdump), arquivos de hashes e modo grafico. Use quando tiver hashes Windows e quiser crackear sem brute force via rainbow tables."
---

# ophcrack

## Objetivo

O Ophcrack e uma ferramenta especializada em cracking de hashes de senha do Windows (LM e NTLM) usando rainbow tables pre-computadas. Ao contrario de ferramentas de brute force que testam senha por senha, o ophcrack faz um lookup direto na rainbow table - tornando o processo ordens de magnitude mais rapido para hashes LM e NTLM de senhas curtas/alfanumericas. Casos de uso principais:

- Cracking de hashes LM (Windows XP e anteriores) com rainbow tables gratuitas
- Cracking de hashes NTLM (Windows Vista/7/10/11) com tabelas especializadas
- Processamento de arquivos pwdump extraidos do SAM do Windows
- Cracking offline de hashes obtidos via ferramentas como Mimikatz, Secretsdump, ou extrados do SAM
- Alternativa rapida ao brute force para senhas alfanumericas de ate 14 caracteres (LM) ou 8-10 chars (NTLM)
- Identificacao do tipo de hash (LM vs NTLM) para escolher a tabela correta

## Endpoint

```
POST /api/tools/run
```

## Requer target

Nao. O ophcrack trabalha offline com hashes, nao com hosts de rede. O "target" sao os hashes ou arquivos de hash fornecidos via opcoes.

## Parametros

| Parametro | Tipo   | Obrigatorio | Descricao                                                                       |
|-----------|--------|-------------|---------------------------------------------------------------------------------|
| tool      | string | Sim         | Deve ser "ophcrack"                                                             |
| options   | string | Sim         | Flags do CLI incluindo -d (tabelas) e -h ou -f (hashes)                        |

## Flags Importantes

| Flag          | Descricao                                                                               |
|---------------|-----------------------------------------------------------------------------------------|
| -d dir        | Diretorio contendo as rainbow tables (OBRIGATORIO). Ex: /usr/share/ophcrack/tables/     |
| -h hash       | Hash unico a crackar. Formato: hash ou LMhash:NThash                                    |
| -f arquivo    | Arquivo de hashes no formato pwdump (usuario:id:LMhash:NThash:::) (OBRIGATORIO se -h nao usado) |
| -t tipo       | Tipo de hash: lm (LM hash), nt (NT/NTLM hash), vista (hash Vista/7/10)                 |
| -v            | Verbose: exibe progresso e estatisticas durante o cracking                              |
| -l logfile    | Salva resultados em arquivo de log                                                      |
| -s            | Exibe estatisticas das rainbow tables carregadas (cobertura, tamanho, etc.)             |
| -n N          | Numero de threads para processamento paralelo das tabelas                               |
| -a            | Usa o algoritmo de brute force alem das rainbow tables (mais lento, maior cobertura)    |
| -c            | Limpa (crack) todos os hashes encontrados no arquivo -f                                 |
| -o dir        | Diretorio de saida para resultados                                                      |

### Rainbow Tables Disponiveis

| Tabela              | Tipo | Tamanho | Cobertura                                    | Download        |
|---------------------|------|---------|----------------------------------------------|-----------------|
| XP free small       | LM   | 388 MB  | Alfanum maiusculo 99.9% ate 7 chars          | Gratuita        |
| XP free fast        | LM   | 703 MB  | Alfanum maiusculo 99.9% ate 7 chars (rapida) | Gratuita        |
| XP special          | LM   | 7.5 GB  | Alfa+especiais ate 14 chars                  | Paga            |
| Vista free (7alfa)  | NT   | 461 MB  | Alfanumerico ate 8 chars                     | Gratuita        |
| Vista special       | NT   | 14 GB   | Alfa+especiais ate 10 chars                  | Paga            |
| Vista probabilistic | NT   | 3 GB    | Senhas alfanum de alta probabilidade          | Paga            |

### Formato de Hashes Suportados

Formato pwdump (arquivo -f):
```
usuario:RID:LMhash:NThash:::
Administrador:500:e52cac67419a9a224a3b108f3fa6cb6d:8846f7eaee8fb117ad06bdd830b7586c:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
```

Hash individual via -h:
```
-h 8846f7eaee8fb117ad06bdd830b7586c               # Hash NT isolado
-h aad3b435b51404eeaad3b435b51404ee:8846...       # LMhash:NThash
```

O hash LM aad3b435b51404eeaad3b435b51404ee indica que a senha NAO tem hash LM (Windows Vista+).
Nesse caso, somente NTLM cracking e possivel.

## Exemplos

### Caso 1 - Cracking de arquivo pwdump com tabelas Vista gratuitas

```json
{
  "tool": "ophcrack",
  "options": "-d /usr/share/ophcrack/vista_free -f /tmp/hashes.txt -t vista -v -l /tmp/ophcrack_results.txt"
}
```

Comando CLI equivalente:
```
ophcrack -d /usr/share/ophcrack/vista_free -f /tmp/hashes.txt -t vista -v -l /tmp/ophcrack_results.txt
```

Use quando os hashes foram extraidos de sistemas Windows Vista/7/8/10/11.
A tabela vista_free (7alfa, 461MB) cobre senhas alfanumericas de ate 8 caracteres.

### Caso 2 - Cracking de hashes LM (Windows XP e anteriores)

```json
{
  "tool": "ophcrack",
  "options": "-d /usr/share/ophcrack/xp_free_fast -f /tmp/xp_hashes.txt -t lm -v"
}
```

Comando CLI equivalente:
```
ophcrack -d /usr/share/ophcrack/xp_free_fast -f /tmp/xp_hashes.txt -t lm -v
```

Hashes LM sao extremamente fracos: a senha e dividida em dois blocos de 7 chars, convertida para
maiusculo e hashada separadamente. As tabelas XP free tem ~99.9% de cobertura para senhas alfanumericas.

### Caso 3 - Cracking de hash unico (NTLM isolado)

```json
{
  "tool": "ophcrack",
  "options": "-d /usr/share/ophcrack/vista_free -h 8846f7eaee8fb117ad06bdd830b7586c -t nt -v"
}
```

Comando CLI equivalente:
```
ophcrack -d /usr/share/ophcrack/vista_free -h 8846f7eaee8fb117ad06bdd830b7586c -t nt -v
```

O hash 8846f7eaee8fb117ad06bdd830b7586c e o NTLM da senha "password" - util para validar
que as tabelas estao funcionando corretamente antes de lancar contra hashes reais.

### Caso 4 - Verificar estatisticas das rainbow tables antes do ataque

```json
{
  "tool": "ophcrack",
  "options": "-d /usr/share/ophcrack/vista_free -s -v"
}
```

Comando CLI equivalente:
```
ophcrack -d /usr/share/ophcrack/vista_free -s -v
```

Exibe informacoes sobre as tabelas carregadas: numero de chains, cobertura percentual estimada,
espaco de busca coberto e taxa de sucesso esperada. Util para validar que as tabelas estao
integras e selecionar as tabelas corretas antes de processar os hashes.

### Caso 5 - Cracking com tabelas especiais de maior cobertura e multiplas threads

```json
{
  "tool": "ophcrack",
  "options": "-d /usr/share/ophcrack/vista_special -f /tmp/hashes.txt -t vista -n 4 -v -l /tmp/results_special.txt"
}
```

Comando CLI equivalente:
```
ophcrack -d /usr/share/ophcrack/vista_special -f /tmp/hashes.txt -t vista -n 4 -v -l /tmp/results_special.txt
```

A tabela vista_special (14GB) cobre senhas com caracteres especiais e ate 10 chars.
Use -n 4 para paralelizar o processamento em sistemas com multiplos nucleos.
Recomendado quando a tabela gratuita falha em crackear os hashes.

## OPSEC

- **Operacao 100% offline**: O ophcrack nao faz nenhuma comunicacao de rede. Todo o cracking e feito localmente contra os hashes. Nao ha risco de deteccao pelo alvo durante o cracking.
- **LM hash e extremamente fraco**: Se o alvo tem hashes LM (aad3b435... nao encontrado), a senha e crackeada em minutos com as tabelas XP free. Sistemas Windows Vista+ tem LM desabilitado por padrao.
- **NTLM tem limitacoes**: As tabelas NTLM gratuitas (vista_free, 461MB) cobrem apenas senhas alfanumericas simples de ate 8 chars. Senhas com especiais ou longas requerem tabelas pagas ou brute force (Hashcat).
- **Obter hashes do SAM**: Os hashes Windows ficam em C:\Windows\System32\config\SAM (bloqueado em uso). Obtenha via: Volume Shadow Copy, Mimikatz (sekurlsa::logonpasswords), Impacket secretsdump.py, ou boot de Live CD.
- **Formato pwdump**: Confirme que o arquivo esta no formato correto antes de usar -f. Um formato incorreto faz o ophcrack falhar silenciosamente sem processar hashes.
- **Tabelas corretas por versao Windows**:
    - Windows XP e anterior: use tabelas XP (LM hash presente)
    - Windows Vista/7/8/10/11: use tabelas Vista (apenas NTLM)
    - Para confirmar: se LMhash = aad3b435b51404eeaad3b435b51404ee, nao ha hash LM
- **Alternativas quando ophcrack falha**: Para senhas longas ou com especiais, use Hashcat com -m 1000 (NTLM) e ataque de dicionario (-a 0) ou regras (-r rules/best64.rule).
- **Espaco em disco para tabelas**: Vista special requer 14GB livres. Verifique espaco disponivel antes de baixar. As tabelas gratuitas (461MB) sao suficientes para senhas simples e sao um bom ponto de partida.

## Saida

A API retorna um objeto JSON com os seguintes campos:

| Campo     | Tipo    | Descricao                                                                  |
|-----------|---------|----------------------------------------------------------------------------|
| success   | boolean | true se a execucao ocorreu sem erros fatais                                |
| stdout    | string  | Saida padrao com senhas crackeadas e estatisticas de progresso             |
| stderr    | string  | Erros e avisos emitidos pelo ophcrack (tabela nao encontrada, etc.)        |
| report    | string  | Resumo estruturado da API com pares usuario:senha crackeados               |
| artifacts | array   | Lista de arquivos de log gerados (-l)                                      |

Exemplo de stdout com sucesso:
```
Using 1 table from /usr/share/ophcrack/vista_free
Loaded 3 password hashes

Results:
hash = 8846f7eaee8fb117ad06bdd830b7586c
user = Administrador
pwd = password

Statistics: 3 hashes found, 1 cracked (33.33%), 2 not found
```

Exemplo quando hash nao e encontrado nas tabelas:
```
Results:
hash = a87f3a337d73085c45f9416be5787d86
user = usuario2
pwd = (not found)
```
Quando a senha nao e encontrada, use Hashcat com modo NTLM (-m 1000) e wordlists ou brute force.
