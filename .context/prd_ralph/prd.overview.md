# PRD Overview: rclone_new_remotes

- File: .context/prd_ralph/prd.json
- Stories: 5 total (4 open, 0 in_progress, 1 done)

## Quality Gates
- bash -n rclone_new_remotes.sh
- python3 -m py_compile obsidian_profile_portability.py
- test -f .context/docs/README.md
- jq . .context/prd_ralph/prd.json >/dev/null
- git status --porcelain

## Stories
- [done] S1: Consolidar contexto oficial do projeto para o ciclo Ralph
- [open] S2: Estabelecer baseline e backup antes de ativar Google Drive direto (depends on: S1)
- [open] S3: Definir fluxo seguro para ativação direcionada do remote Google Drive (depends on: S2)
- [open] S4: Validar Google Drive direto sem regressão nos demais remotes e systemd (depends on: S3)
- [open] S5: Fechar ciclo com rollback validado e checklist de operação contínua (depends on: S4)
