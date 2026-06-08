# Fluxo seguro de ativação seletiva do Google Drive

- Atualizado em: 2026-06-08
- Script operacional: `./rclone_new_remotes.sh`
- Remote alvo principal: `Google Drive:`

## Uso interativo

Para rodar o setup completo em um terminal real:

```bash
./rclone_new_remotes.sh --setup
```

O script abre um menu TTY para ligar/desligar remotes:

- `↑` e `↓` navegam pela lista
- `espaço` alterna on/off do remote selecionado
- `Enter` aplica a seleção
- `a` liga todos
- `n` desliga todos
- `q` cancela sem aplicar
- a legenda abaixo da lista descreve o remote selecionado

Para ativar apenas o Google Drive, deixe marcado somente `Google Drive` e pressione `Enter`.

## Abrir só o menu on/off

Para abrir o PTY e aplicar apenas liga/desliga nos serviços systemd existentes, sem criar remotes, sem renovar tokens, sem recriar WebDAV agregado ou rodar o setup completo:

```bash
./rclone_new_remotes.sh --manage
```

Esse modo respeita a mesma seleção do menu. Remotes marcados como on passam por uma checagem rápida de acesso antes de reiniciar/habilitar a unit existente. Se a autenticação estiver expirada, o serviço não é iniciado e o script mostra o comando `rclone config reconnect`. Remotes marcados como off são parados/desabilitados.

## Semântica de on/off

- On: o script cria/atualiza a configuração do remote, valida autenticação quando aplicável, cria/atualiza a unit systemd, reinicia e habilita o serviço.
- Off: o script desmonta o mount local, para a unit systemd e desabilita o serviço.
- Off não apaga a configuração do remote em `~/.config/rclone/rclone.conf`.

## Modo destrutivo

O prompt antigo de apagar todos os remotes foi removido do fluxo padrão. A recriação destrutiva só roda com opt-in explícito:

```bash
RCLONE_NUKE_ALL=true ./rclone_new_remotes.sh --setup
```

Use esse modo apenas depois de baseline e plano de rollback.

## Ajuda

```bash
./rclone_new_remotes.sh --help
```


## Fallback sem TTY

Quando o script roda sem terminal interativo, ele mantém todos os remotes ligados. Esse fallback evita desligamento acidental em execução não interativa.

## Validação mínima

```bash
bash -n rclone_new_remotes.sh
rclone about 'Google Drive:'
systemctl --user status rclone-google-drive.service --no-pager
```
