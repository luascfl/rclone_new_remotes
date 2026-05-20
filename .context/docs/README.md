# Documentation index

Comece por `project-overview.md`. Em seguida, use os guias específicos conforme a story ativa.

## Core guides

- [Project overview](./project-overview.md)
- [Architecture notes](./architecture.md)
- [Development workflow](./development-workflow.md)
- [Testing strategy](./testing-strategy.md)
- [Glossary and domain concepts](./glossary.md)
- [Data flow and integrations](./data-flow.md)
- [Security and compliance notes](./security.md)
- [Tooling and productivity guide](./tooling.md)

## Planning guides

- [GSD project plan](./planning_gsd/PROJECT.md)
- [GSD current state](./planning_gsd/STATE.md)
- [Ralph PRD README](../prd_ralph/README.md)
- [Ralph PRD JSON](../prd_ralph/prd.json)

## Operational guides

- [Baseline de remotes](./ops/baseline-remotes.md)
- [Baseline de systemd](./ops/baseline-systemd.md)
- [Playbook de restore](./ops/restore-playbook.md)
- [Relatório de ativação do Google Drive](./ops/google-drive-activation-report.md)

## Repository snapshot

- `rclone_new_remotes.sh` — orquestração principal de remotes `rclone`
- `obsidian_profile_portability.py` — utilitário Obsidian
- `create_and_push_repo.sh` — automação Git/GitHub paralela
- `remotely-save-src/` — subtree vendorizado do plugin Remotely Save
- `ralph` CLI global — executor de stories do fluxo Ralph
- `.context/docs/` — contexto curado do projeto

## Document map

| Guide | File | Primary inputs |
| --- | --- | --- |
| Project overview | `project-overview.md` | `rclone_new_remotes.sh`, árvore do repo, estado atual do workspace |
| Architecture notes | `architecture.md` | funções e fluxo principal do shell, papel do subtree vendorizado |
| Development workflow | `development-workflow.md` | práticas operacionais, verificação local, higiene Git |
| Testing strategy | `testing-strategy.md` | validação shell, Python e subtree TypeScript |
| Glossary | `glossary.md` | termos do domínio `rclone`, mounts e workflow |
| Data flow | `data-flow.md` | entradas de configuração, integrações e persistência |
| Security | `security.md` | segredos, risco operacional e higiene documental |
| Tooling | `tooling.md` | `rclone`, `systemd --user`, `python3`, `jq`, `ralph` |
| GSD project plan | `planning_gsd/PROJECT.md` | milestones, dependências e critérios de saída |
| GSD current state | `planning_gsd/STATE.md` | fase ativa, story recomendada e evidências |
| Baseline de remotes | `ops/baseline-remotes.md` | `rclone listremotes`, `rclone about 'Google Drive:'` |
| Baseline de systemd | `ops/baseline-systemd.md` | `systemctl --user list-unit-files`, `list-units`, restart aplicado |
| Restore playbook | `ops/restore-playbook.md` | backup bruto de `rclone.conf` e units do usuário |
| Activation report | `ops/google-drive-activation-report.md` | reconexão do remote alvo e validação pós restart |

## Notes

`codebase-map.json` existe para consulta estrutural, mas hoje superrepresenta o subtree `remotely-save-src`. Use-o como inventário auxiliar, não como leitura prioritária do fluxo principal.