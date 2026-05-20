# GSD state

- Updated: 2026-05-20
- Phase: validation
- Initiative: ativação segura do remote `Google Drive` no script principal
- Active milestone: M2. Ativação direcionada de Google Drive
- Story concluída neste ciclo: S2. Estabelecer baseline e backup antes de ativar Google Drive direto
- Próxima story recomendada: S3. Definir fluxo seguro para ativação direcionada do remote Google Drive
- Ralph PRD: `./.context/prd_ralph/prd.json`

## Estado atual do projeto

- Entrypoint operacional confirmado: `./rclone_new_remotes.sh`.
- Utilitário auxiliar confirmado: `./obsidian_profile_portability.py`.
- `./README.md` ausente na raiz e `./GEMINI.md` local ausente.
- `./remotely-save-src/` mantido como subtree vendorizado fora do escopo imediato.
- Repositório com drift pré-existente fora deste ciclo: `remotely-save-src` modificado e `create_and_push_repo.sh` não rastreado.

## Evidência operacional observada

### Antes da correção

- `rclone listremotes` confirmava que `Google Drive:` já existia.
- `rclone about 'Google Drive:'` falhava com `invalid_grant`.
- `rclone-google-drive.service` estava em `activating/auto-restart`.
- `rclone-webdav-todos-remotes.service` também estava em `activating/auto-restart`.

### Ação aplicada

- baseline bruto salvo em `/home/lucas/.local/state/rclone_new_remotes/baselines/20260520-084942/`
- reconexão executada com `rclone config reconnect 'Google Drive:'`
- restart executado em:
  - `rclone-google-drive.service`
  - `rclone-webdav-todos-remotes.service`

### Depois da correção

- `rclone about 'Google Drive:'` responde com quota total e uso.
- `rclone-google-drive.service` está `active (running)`.
- `rclone-webdav-todos-remotes.service` está `active (running)`.
- o mount local `/home/lucas/Google Drive` voltou a listar conteúdo.

## Artefatos produzidos neste ciclo

- `./.context/docs/ops/baseline-remotes.md`
- `./.context/docs/ops/baseline-systemd.md`
- `./.context/docs/ops/restore-playbook.md`
- `./.context/docs/ops/google-drive-activation-report.md`

## Próximos passos objetivos

1. Atualizar o PRD para refletir S2 como concluída.
2. Implementar endurecimento do fluxo em `rclone_new_remotes.sh` para permitir ativação direcionada sem prompt destrutivo global (`S3`).
3. Transformar a correção operacional manual em procedimento previsível e repetível no repositório.

## Restrições ativas

- Não executar deleção em massa sem baseline e plano de rollback.
- Não tratar `remotely-save-src/` como foco principal deste ciclo.
- Não registrar segredos em texto claro na documentação oficial.

## Pronto para execução

Sim. O remote `Google Drive` está ativo. O próximo ciclo de código deve iniciar em `S3`.