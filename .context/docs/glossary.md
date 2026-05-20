# Glossary and domain concepts

## Remote

Entrada lógica do `rclone` configurada em `rclone.conf`. Exemplo: `Google Drive`, `Koofr`, `OneDrive`.

## Provider

Tipo de backend usado por um remote. No script atual aparecem `google`, `onedrive`, `sharepoint`, `mega`, `koofr`, `pcloud`, `webdav` e `googlephotos`.

## Direct Google Drive

Remote `Google Drive` configurado com backend nativo `drive` do `rclone`, não via Koofr/WebDAV. É o foco do próximo ciclo.

## Team drive / shared drive

Remote Google Drive criado com `team_drive=<id>` para áreas compartilhadas específicas, como `FINANCEIRO` ou `PRESIDENCIA`.

## Mount point

Diretório local em `/home/lucas/<Nome do Remote>` onde o `rclone mount` expõe os arquivos do remote.

## User service

Unit `systemd --user` que sobe um mount de forma persistente. Exemplo: `rclone-google-drive.service`.

## WebDAV agregado

Serviço local derivado de um remote `combine` que expõe vários remotes por uma única interface HTTPS. No script, o nome lógico é `Todos Remotes`.

## GVFS alias

Atalho manual para o caminho montado pelo ambiente gráfico em `/run/user/1000/gvfs/...`. Serve para navegação manual, não para automação.

## OAuth reconnect

Passo interativo necessário para concluir ou renovar autenticação de remotes como Google Drive e OneDrive. No fluxo atual aparece como `rclone config reconnect "<remote>:"`.

## Nuke mode

Fluxo destrutivo de apagar e recriar todos os remotes. Hoje é controlado por prompt no início do script. É a principal área de risco operacional.

## Health check

Checagem simples de acesso ao remote, normalmente via `rclone about` e, em casos específicos, `rclone lsd`.

## Baseline

Snapshot do estado anterior a uma mudança. Para este projeto inclui `rclone.conf`, lista de remotes, status das units e eventualmente logs de validação.

## Remotely Save subtree

Diretório `remotely-save-src/` com o código do plugin Obsidian. É um contexto técnico relacionado, mas não deve ser confundido com o script operacional principal.

## PRD

Documento JSON em `.context/prd_ralph/prd.json` que define stories, dependências e quality gates para o ciclo Ralph.

## GSD state

Estado resumido do planejamento macro em `.context/docs/planning_gsd/STATE.md`, com milestone ativa, dependências e próximos passos.