# Baseline de remotes

- Coletado em: 2026-05-20T09:10:54-03:00
- Backup bruto de `rclone.conf`: `/home/lucas/.local/state/rclone_new_remotes/baselines/20260520-084942/rclone.conf`
- Objetivo: registrar o estado dos remotes antes de qualquer mudança funcional no script `rclone_new_remotes.sh`

## Inventário retornado por `rclone listremotes`

```text
Google Drive:
Psicologia UNEB 2026.1:
Arquivos e cursos:
Documentos compartilhados OrganizeJr:
presidencia to lucascamilo:
PRESIDENCIA:
Filmes - Lucas aluno.colegiomaanaim.net:
MEJ - Lucas organizejr.com:
FINANCEIRO:
LM Mobilidade OneDrive:
OneDrive:
Mega:
Pcloud:
Koofr WebDAV GDrive:
Google Photos:
COMERCIAL:
Todos Remotes:
```

## Estado observado do remote alvo antes da reconexão

Comando executado:

```bash
rclone about 'Google Drive:'
```

Resultado observado antes da correção:

```text
CRITICAL: Failed to create file system for "Google Drive:": ... couldn't fetch token: invalid_grant: maybe token expired? - try refreshing with "rclone config reconnect Google Drive:"
```

## Estado observado após a reconexão

Comando executado:

```bash
rclone about 'Google Drive:'
```

Resultado observado após a correção:

```text
Total:   5 TiB
Used:    42.147 GiB
Free:    4.958 TiB
Trashed: 9.081 GiB
Other:   1.360 GiB
```

## Observações

- Nenhum remote foi deletado.
- A correção foi operacional, via `rclone config reconnect 'Google Drive:'`.
- Não houve alteração em `rclone_new_remotes.sh` nesta ativação.