# Tooling and productivity guide

## Core operational tools

### `rclone`

Ferramenta central do projeto. Usada para:

- criar remotes;
- reconectar OAuth;
- validar acesso com `about` e `lsd`;
- montar storages remotos no filesystem local;
- servir WebDAV agregado.

### `systemctl --user`

Gerencia a vida útil dos mounts criados pelo script. Os comandos mais úteis no ciclo atual são:

- `systemctl --user daemon-reload`
- `systemctl --user status <unit> --no-pager`
- `systemctl --user list-unit-files 'rclone-*.service'`
- `systemctl --user --failed`

### `fusermount`

Usado no stop/restart de mounts FUSE.

### `openssl`

Suporta a geração de material TLS para o WebDAV agregado.

### `python3`

Necessário para `obsidian_profile_portability.py` e para validações simples como `python3 -m py_compile` ou `python3 -m json.tool`.

### `jq`

Útil para validar e consultar o PRD JSON em `.context/prd_ralph/prd.json`.

## Planning and execution tools

### Ralph

Use a CLI global `ralph` com artefatos oficiais em `.context/prd_ralph/`.

Comandos úteis:

- `ralph ping --agent codex`
- `ralph overview --prd .context/prd_ralph/prd.json`
- `ralph build 1 --no-commit --prd .context/prd_ralph/prd.json`

Se o mapeamento padrão do agente falhar no ambiente local, ajuste a configuração local do Ralph antes de tentar executar stories.

### AI Coders Context

Usado para scaffold e curadoria de `.context/docs/`. Não confie cegamente no `codebase-map.json` quando o repo tiver código vendorizado com mais volume que o entrypoint real.

## TypeScript subtree tools

Dentro de `remotely-save-src/`:

- `npm test`
- `npm run build`
- `npm run dev`

Use esses comandos só se o ciclo tocar o subtree.

## Suggested command sequence for the next cycle

1. `git status --short --branch`
2. `bash -n rclone_new_remotes.sh`
3. `rclone listremotes`
4. `systemctl --user list-unit-files 'rclone-*.service'`
5. `ralph overview --prd .context/prd_ralph/prd.json`

## Productivity guardrails

- não rode o prompt destrutivo de recriação em massa sem baseline;
- não use o subtree `remotely-save-src` como desculpa para validar o shell principal;
- prefira um remote alvo por vez quando houver autenticação interativa;
- atualize `.context/docs/` no mesmo ciclo em que mudar comportamento operacional.