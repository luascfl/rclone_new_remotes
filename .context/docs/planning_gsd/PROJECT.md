# GSD project plan

## Goal

Estruturar este repositório com contexto oficial mínimo e conduzir a ativação segura do remote direto `Google Drive` em `rclone_new_remotes.sh`, sem regressão nos demais remotes e serviços `systemd --user`.

## Canonical scope

- `rclone_new_remotes.sh`
- `obsidian_profile_portability.py`, apenas se o ciclo tocar suporte Obsidian
- `.context/docs/`
- `.context/prd_ralph/`
- `.context/workflow/`

`remotely-save-src/` fica fora do fluxo principal, salvo story explícita.

## Milestones

### M1. Bootstrap de contexto e baseline operacional

Objetivo:

- curar documentação mínima real do repo;
- registrar milestone e estado atual;
- preparar baseline de `rclone.conf`, remotes e units antes de qualquer mutação.

Saídas esperadas:

- `.context/docs/` preenchido com foco operacional
- `.context/prd_ralph/prd.json`
- `.context/prd_ralph/README.md`
- baseline de remotes e systemd em `.context/docs/ops/`

### M2. Ativação direcionada de Google Drive

Objetivo:

- evitar o fluxo global destrutivo;
- permitir validação segura do remote `Google Drive` e sua unit correspondente.

Saídas esperadas:

- ajuste no `rclone_new_remotes.sh` para fluxo direcionado ou equivalente seguro
- runbook operacional de ativação
- evidência de validação do remote alvo

### M3. Estabilização e rollback

Objetivo:

- consolidar recuperação rápida;
- documentar operação contínua;
- fechar o ciclo com evidência técnica rastreável.

Saídas esperadas:

- playbook de restore
- checklist de operação contínua
- relatório de validação pós ativação

## Dependencies

- acesso ao `rclone` no host local
- acesso ao `systemd --user`
- navegador disponível para OAuth interativo quando necessário
- permissão para ler o estado atual dos remotes sem apagá-los

## Risks

- uso acidental do modo destrutivo de recriação global
- credenciais presentes em arquivos locais
- drift pré existente no repositório, especialmente no checkout `remotely-save-src`
- reinício em massa de units quando o objetivo é validar só um remote

## Exit criteria for the current initiative

- `Google Drive` validado com evidência objetiva
- nenhum remote crítico perdido por efeito colateral
- rollback documentado e executável
- contexto oficial atualizado no mesmo ciclo