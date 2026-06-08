# GSD state

- Updated: 2026-06-08
- Phase: validation
- Initiative: ativação segura e seletiva de remotes `rclone` no script principal
- Active milestone: M2. Ativação direcionada de Google Drive
- Story concluída neste ciclo: S3. Definir fluxo seguro para ativação direcionada do remote Google Drive
- Próxima story recomendada: S4. Validar Google Drive direto sem regressão nos demais remotes e systemd
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

1. Executar validação operacional da seleção interativa em sessão real de terminal.
2. Validar Google Drive direto e WebDAV agregado com apenas os remotes ligados no seletor.
3. Confirmar que remotes desligados permanecem com configuração `rclone` preservada e serviço systemd desabilitado.

## Restrições ativas

- Não executar deleção em massa sem baseline e plano de rollback.
- Não tratar `remotely-save-src/` como foco principal deste ciclo.
- Não registrar segredos em texto claro na documentação oficial.

## Evidência deste ciclo

- O script `rclone_new_remotes.sh` agora abre um seletor interativo em TTY para ligar/desligar remotes com setas e espaço.
- Remotes desligados param/desabilitam o serviço systemd e desmontam o ponto local sem apagar a configuração do `rclone`.
- Sem TTY interativo, o script mantém fallback conservador com todos os remotes ligados.
- Validações deste ciclo:
  - `bash -n rclone_new_remotes.sh`
  - harness não interativo das funções do seletor
  - harness PTY simulando espaço e Enter no menu

## Pronto para execução

Sim. O próximo ciclo deve iniciar em `S4`, com validação operacional real dos remotes ligados/desligados.