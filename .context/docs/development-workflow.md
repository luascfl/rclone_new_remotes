# Development workflow

## Working style for this repository

Este repositório pede ciclos curtos e controlados. O risco não está em compilação complexa, está em mexer em credenciais, remotes e serviços persistentes do usuário.

## Baseline before changes

Antes de qualquer alteração comportamental:

1. rode `git status --short --branch`;
2. registre se há drift pré existente, hoje já existe pelo menos um checkout sujo em `remotely-save-src`;
3. capture baseline do `rclone.conf`, `rclone listremotes` e units `systemd --user` relevantes;
4. confirme se o ciclo toca só `rclone_new_remotes.sh` ou também `obsidian_profile_portability.py` e `remotely-save-src/`.

## Source of truth

- automação operacional: `rclone_new_remotes.sh`
- utilitário Obsidian: `obsidian_profile_portability.py`
- contexto curado: `.context/docs/`
- stories e gates: `.context/prd_ralph/prd.json`
- workflow PREVC: `.context/workflow/`

README de raiz e `GEMINI.md` não existiam no início deste ciclo. Não trate arquivos ausentes como documentação implícita.

## Planning flow

1. atualize `.context/docs/planning_gsd/PROJECT.md` quando milestone ou dependências mudarem;
2. atualize `.context/docs/planning_gsd/STATE.md` com fase ativa, story escolhida, riscos e evidências;
3. selecione exatamente uma story do PRD por ciclo Ralph.

## Editing rules

- prefira mudanças pequenas e reversíveis no shell script principal;
- não altere comportamento de todos os remotes quando o objetivo for validar só `Google Drive`;
- mantenha nomes de remotes e caminhos estáveis, a menos que a story peça migração explícita;
- se tocar `remotely-save-src/`, use o workflow próprio do subtree e testes localizados.

## Verification commands

### Para mudanças no shell principal

- `bash -n rclone_new_remotes.sh`
- comandos `rclone` somente no escopo do remote afetado
- `systemctl --user status <unit>` para as units impactadas

### Para mudanças no utilitário Python

- `python3 -m py_compile obsidian_profile_portability.py`

### Para mudanças no subtree vendorizado

Dentro de `remotely-save-src/`:

- `npm test`
- `npm run build` se a story mexer em código distribuível

## Evidence discipline

Toda story precisa deixar rastros objetivos:

- arquivo de baseline ou relatório em `.context/docs/ops/`, quando houver execução operacional;
- comando de verificação e resultado observado;
- atualização do estado em `STATE.md`.

## Git hygiene

O repositório tem remoto GitHub e já contém alterações pré existentes. Não reverta trabalho alheio. Separe claramente os arquivos do ciclo atual antes de preparar commit.

## Default cycle shape

1. planejar
2. gerar baseline
3. fazer a menor mudança segura
4. validar com comandos direcionados
5. atualizar contexto
6. só então preparar fechamento