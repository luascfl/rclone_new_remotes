# Testing strategy

## Reality of the current repo

O repositório mistura automação operacional e código vendorizado. A estratégia de teste precisa reconhecer isso.

- `rclone_new_remotes.sh` não tem suíte automatizada própria.
- `obsidian_profile_portability.py` também não tem testes dedicados no repositório raiz.
- `remotely-save-src/` traz uma suíte mocha própria, mas ela cobre o subtree TypeScript, não o shell principal.

## Test layers by area

### Shell orchestration

Para `rclone_new_remotes.sh`, o mínimo aceitável por mudança é:

1. `bash -n rclone_new_remotes.sh`
2. validação direcionada dos blocos afetados com comandos `rclone`
3. checagem da unit `systemd --user` correspondente
4. registro de evidência no contexto

### Python utility

Para `obsidian_profile_portability.py`:

1. `python3 -m py_compile obsidian_profile_portability.py`
2. se a mudança tocar comportamento, rodar um cenário de `verify`, `export` ou `apply` em ambiente seguro

### Vendored TypeScript subtree

Para `remotely-save-src/`:

1. `npm test`
2. `npm run build` quando a story alterar código distribuível
3. testes localizados primeiro, antes de rodar a suíte completa

## Preferred validation style for the next cycle

Como o objetivo imediato é ativar `Google Drive` com segurança, a validação deve ser focada em comportamento observável:

- remote existe ou foi criado corretamente;
- autenticação responde sem erro;
- mount sobe na unit correta;
- outros serviços não entram em falha por efeito colateral.

## Commands expected in the Google Drive activation cycle

- `bash -n rclone_new_remotes.sh`
- `rclone listremotes`
- `rclone about 'Google Drive:'`
- `systemctl --user status 'rclone-google-drive.service' --no-pager`
- `systemctl --user --failed`

## What does not count as enough evidence

- só editar documentação sem baseline operacional;
- só rodar `bash -n` em uma mudança de comportamento;
- validar um remote alvo sem checar impacto no serviço correspondente;
- assumir que o subtree `remotely-save-src` cobre o shell principal.

## Regression scope

Toda story deve declarar claramente qual destas áreas foi tocada:

- remotes e autenticação
- geração de units `systemd`
- WebDAV agregado
- utilitário Obsidian
- subtree `remotely-save-src`

A verificação precisa mirar a área alterada e as dependências imediatamente afetadas, não o repositório inteiro por padrão.