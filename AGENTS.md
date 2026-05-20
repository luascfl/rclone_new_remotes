# AGENTS.md

## Project focus

Este repositório é um workspace pessoal de automação local. O entrypoint principal do ciclo atual é `rclone_new_remotes.sh`, não `remotely-save-src/`.

## Where to work

- `rclone_new_remotes.sh` — fluxo principal de criação, validação e subida de remotes `rclone`
- `obsidian_profile_portability.py` — utilitário Python separado para configuração do Obsidian
- `remotely-save-src/` — subtree vendorizado, só toque se a story pedir mudança nele
- `.context/docs/` — documentação curada do projeto
- `.context/prd_ralph/prd.json` — stories, dependências e quality gates do Ralph

## Repo truths

- `README.md` de raiz está ausente neste projeto
- `GEMINI.md` local também está ausente neste momento
- o repositório já tem drift pré existente, valide com `git status --short --branch` antes de editar

## Validation commands

### Shell principal

- `bash -n rclone_new_remotes.sh`
- `rclone listremotes`
- `systemctl --user status <unit> --no-pager`

### Python

- `python3 -m py_compile obsidian_profile_portability.py`

### Subtree vendorizado

Dentro de `remotely-save-src/`:

- `npm test`
- `npm run build`

## Guardrails

- não rode deleção em massa de remotes sem baseline e rollback
- não trate `remotely-save-src/` como se fosse o entrypoint operacional do repo
- não documente credenciais, tokens ou secrets em `.context/docs/`
- uma story por ciclo Ralph