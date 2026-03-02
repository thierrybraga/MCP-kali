---
name: apktool
description: Ferramenta essencial para engenharia reversa de aplicativos Android (APK). Permite decodificar recursos para forma quase original e reconstruí-los após modificação.
---

# apktool

## Objetivo
- Decodificar arquivos APK para análise de código (Smali) e recursos (XML)
- Modificar código e recursos de aplicativos Android
- Reconstruir (build) APKs modificados
- Analisar `AndroidManifest.xml` em formato legível

## Endpoint
- `/api/tools/run` (tool: "apktool")

## Requer target
- sim (caminho para o arquivo APK ou diretório do projeto)

## Parâmetros
| Parâmetro | Tipo   | Obrigatório | Descrição                                             |
|-----------|--------|-------------|-------------------------------------------------------|
| tool      | string | sim         | "apktool"                                             |
| target    | string | sim         | Arquivo APK (para decode) ou pasta (para build)       |
| options   | string | sim         | Flags do CLI (ex: `d`, `b`, `-o`)                     |

## Comandos Importantes
| Flag              | Função                                                   |
|-------------------|----------------------------------------------------------|
| `d` (decode)      | Decodifica o APK para uma pasta (smali, res, xml)        |
| `b` (build)       | Reconstrói a pasta do projeto em um novo APK             |
| `-o <path>`       | Especifica o diretório de saída                          |
| `-f` (force)      | Força sobrescrita se o diretório de destino já existir   |
| `-r`              | Não decodificar recursos (mais rápido se foco for só código) |
| `-s`              | Não decodificar fontes (dex)                             |
| `--use-aapt2`     | Usa o binário aapt2 em vez do aapt (para apps novos)     |

## Exemplos

### Caso 1: Decodificar um APK (Engenharia Reversa)
Extrai o APK para uma pasta legível, convertendo classes.dex para Smali e recursos binários para XML.

```json
{
  "tool": "apktool",
  "target": "/uploads/app.apk",
  "options": "d -o /workspace/project_folder -f"
}
```

### Caso 2: Decodificar sem Recursos (Foco em Código)
Mais rápido se o objetivo for apenas analisar a lógica Smali.

```json
{
  "tool": "apktool",
  "target": "/uploads/app.apk",
  "options": "d -r -o /workspace/project_folder"
}
```

### Caso 3: Reconstruir o APK (Build)
Compila a pasta modificada de volta para um arquivo APK (note: o APK gerado não estará assinado).

```json
{
  "tool": "apktool",
  "target": "/workspace/project_folder",
  "options": "b -o /workspace/modded_app.apk"
}
```

## OPSEC & Eficiência
- **Assinatura**: O `apktool` apenas empacota o APK. Para instalar no Android, você DEVE assinar o APK gerado (usando `apksigner` ou `jarsigner`) e alinhar (`zipalign`).
- **Frameworks**: Em alguns casos (APKs de sistema), pode ser necessário instalar frameworks do fabricante (`apktool if framework-res.apk`).
- **Erros de Build**: Modificações incorretas no Smali ou XML frequentemente quebram o build. Teste pequenas alterações por vez.

## Saída
- `success`: execução do comando sem erro.
- `stdout`: log do processo de decode/build.
- `artifacts`: caminho para a pasta ou arquivo gerado.
