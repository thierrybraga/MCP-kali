---
name: volatility
description: Framework avançado de análise forense de memória RAM (Memory Forensics). Permite extrair informações voláteis como processos, conexões de rede, histórico de comandos e artefatos de malware de dumps de memória.
---

# volatility

## Objetivo
- Analisar dumps de memória RAM (raw, crash dumps, hibernação)
- Identificar processos maliciosos e ocultos (rootkits)
- Extrair conexões de rede ativas e encerradas
- Recuperar histórico de comandos (cmd.exe, bash)
- Detectar injeção de código e hooks (malfind, apihooks)
- Extrair hashes de senhas e segredos da memória (hashdump, lsadump)

## Endpoint
- `/api/tools/run` (tool: "volatility")

## Requer target
- sim (o target deve ser o caminho absoluto do arquivo de dump de memória)

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                             |
|-----------|--------|-------------|-------------------------------------------------------|
| tool      | string | sim         | "volatility"                                          |
| target    | string | sim         | Caminho do arquivo de dump (ex: `/tmp/mem.dmp`)       |
| options   | string | sim         | Comandos e plugins do Volatility (ex: `imageinfo`)    |

## Plugins Importantes (Volatility 2)
| Plugin            | Função                                                   |
|-------------------|----------------------------------------------------------|
| `imageinfo`       | Identifica o perfil (OS/Service Pack) sugerido para o dump |
| `pslist` / `pstree` | Lista processos (linear ou árvore)                       |
| `psxview`         | Compara listagens de processos para achar ocultos (rootkits) |
| `netscan` / `connscan` | Lista conexões de rede (TCP/UDP) ativas e antigas    |
| `cmdscan` / `consoles` | Histórico de comandos executados no terminal           |
| `malfind`         | Busca por injeção de código (VAD tags protection)        |
| `dlllist` / `ldrmodules` | Lista DLLs carregadas e módulos desvinculados      |
| `hashdump`        | Extrai hashes de senha (LM/NTLM)                         |
| `filescan`        | Varre a memória por estruturas de arquivos (FILE_OBJECT) |
| `dumpfiles`       | Extrai arquivos da memória para disco                    |

## Exemplos

### Caso 1: Identificar Perfil da Imagem
O primeiro passo obrigatório para configurar o perfil correto (`--profile`).

```json
{
  "tool": "volatility",
  "target": "/evidence/mem.dmp",
  "options": "imageinfo"
}
```

### Caso 2: Listar Processos em Árvore
Visualizar hierarquia de processos para identificar pais suspeitos (ex: `svchost.exe` fora de `services.exe`).

```json
{
  "tool": "volatility",
  "target": "/evidence/mem.dmp",
  "options": "--profile=Win7SP1x64 pstree"
}
```

### Caso 3: Extrair Conexões de Rede
Identificar conexões com C2 (Command & Control) ou exfiltração de dados.

```json
{
  "tool": "volatility",
  "target": "/evidence/mem.dmp",
  "options": "--profile=Win7SP1x64 netscan"
}
```

### Caso 4: Buscar Injeção de Código (Malware)
O plugin `malfind` procura por permissões de memória suspeitas (RWX) e headers PE.

```json
{
  "tool": "volatility",
  "target": "/evidence/mem.dmp",
  "options": "--profile=Win7SP1x64 malfind -D /tmp/dump/"
}
```

### Caso 5: Extrair Hashes de Senha
Recuperar credenciais de usuários logados.

```json
{
  "tool": "volatility",
  "target": "/evidence/mem.dmp",
  "options": "--profile=Win7SP1x64 hashdump"
}
```

## OPSEC & Eficiência
- **Integridade**: Trabalhe sempre em uma cópia do dump, nunca no original. Valide o hash MD5/SHA256 antes e depois.
- **Perfil**: Usar o perfil errado (`--profile`) resultará em saída vazia ou lixo. Use `imageinfo` ou `kdbgscan` para confirmar.
- **Performance**: Plugins como `filescan` e `malfind` varrem toda a memória e podem demorar em dumps grandes (>16GB).
- **Isolamento**: Execute a análise em ambiente isolado, pois você está lidando com artefatos de malware potencialmente ativos se extraídos.

## Saída
- `success`: execução do comando sem erro de processo.
- `stdout`: tabela ou texto com o resultado da análise do plugin.
- `report`: resumo dos artefatos encontrados (se suportado pelo plugin).
