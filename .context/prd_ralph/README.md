# Ralph PRD operacional

Este diretório contém o PRD oficial do ciclo atual do repositório em:

- `./.context/prd_ralph/prd.json`

## Como executar o Ralph neste projeto

A partir da raiz `/home/lucas/Downloads/rclone_new_remotes`:

1. Conferir visão geral da sequência de stories:
   - `ralph overview --prd .context/prd_ralph/prd.json`
2. Executar uma story por ciclo (modo sem commit):
   - `ralph build 1 --no-commit --prd .context/prd_ralph/prd.json`

## Pré-check mínimo antes de stories operacionais de rclone

- `bash -n rclone_new_remotes.sh`
- `rclone listremotes`
- `systemctl --user status <unit> --no-pager`

## Regra de segurança do ciclo

- Não rodar mutação operacional sem baseline de remotes e services.
- Não expor credenciais, tokens ou segredos em `.context/docs/`.
- Tratar `rclone_new_remotes.sh` como entrypoint principal e `remotely-save-src/` como subtree fora do foco, salvo story explícita.

## Sequência atual (PRD)

1. S1. Consolidar contexto oficial do projeto para o ciclo Ralph
2. S2. Estabelecer baseline e backup antes de ativar Google Drive direto
3. S3. Definir fluxo seguro para ativação direcionada do remote Google Drive
4. S4. Validar Google Drive direto sem regressão nos demais remotes e systemd
5. S5. Fechar ciclo com rollback validado e checklist de operação contínua
