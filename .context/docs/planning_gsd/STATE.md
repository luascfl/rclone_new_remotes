# GSD state

- Updated: 2026-05-19
- Phase: planning
- Initiative: ativação segura do remote `Google Drive` no script principal
- Active milestone: M1. Bootstrap de contexto e baseline operacional
- Story em fechamento neste ciclo: S1. Consolidar contexto oficial do projeto para o ciclo Ralph
- Próxima story recomendada: S2. Estabelecer baseline e backup antes de ativar Google Drive direto
- Ralph PRD: `./.context/prd_ralph/prd.json`

## Estado atual do projeto

- Entrypoint operacional confirmado: `./rclone_new_remotes.sh`.
- Utilitário auxiliar confirmado: `./obsidian_profile_portability.py`.
- `./README.md` ausente na raiz e `./GEMINI.md` local ausente.
- `./remotely-save-src/` mantido como subtree vendorizado fora do escopo imediato.
- Repositório com drift pré-existente, então cada ciclo precisa registrar claramente o que foi alterado.
## Evidência operacional observada

- `rclone listremotes` confirma que `Google Drive:` já existe.
- `rclone about 'Google Drive:'` falha com `invalid_grant`, indicando token expirado ou inválido.
- `systemctl --user show rclone-google-drive.service --property=ActiveState,SubState,Result,UnitFileState` mostra a unit em `ActiveState=activating`, `SubState=auto-restart`, `Result=exit-code` e `UnitFileState=enabled`.


## Entregas consolidadas no contexto oficial (S1)

- `./.context/docs/project-overview.md` curado com foco operacional real.
- `./.context/docs/planning_gsd/STATE.md` atualizado com fase, milestone e próximos passos.
- `./.context/prd_ralph/README.md` operacional para execução do `ralph build` com o PRD atual.
- Risco do modo destrutivo (`Apagar e recriar tudo?`) explicitado no contexto.

## Próximos passos objetivos para o ciclo seguro

1. Gerar baseline de remotes e backup antes de qualquer mutação funcional (`S2`).
2. Inventariar units `rclone-*.service` e o serviço agregado `rclone-webdav-todos-remotes.service` (`S2`).
3. Definir fluxo direcionado para `Google Drive` sem deleção global (`S3`).
4. Validar operação e estabilidade sem regressão nos outros remotes (`S4`).

## Restrições ativas

- Não executar deleção em massa sem baseline e plano de rollback.
- Não tratar `remotely-save-src/` como foco principal deste ciclo.
- Não registrar segredos em texto claro na documentação oficial.

## Pronto para execução

Sim. A próxima execução segura deve iniciar em `S2`.
