# Fluxo seguro de ativação seletiva do Google Drive

- Atualizado em: 2026-06-08
- Script operacional: `./rclone_new_remotes.sh`
- Remote alvo principal: `Google Drive:`

## Uso interativo

Execute o script em um terminal real:

```bash
./rclone_new_remotes.sh
```

O script abre um menu TTY para ligar/desligar remotes:

- `↑` e `↓` navegam pela lista
- `espaço` alterna on/off do remote selecionado
- `Enter` aplica a seleção
- `a` liga todos
- `n` desliga todos
- `q` cancela sem aplicar

Para ativar apenas o Google Drive, deixe marcado somente `Google Drive` e pressione `Enter`.

## Semântica de on/off

- On: o script cria/atualiza a configuração do remote, valida autenticação quando aplicável, cria/atualiza a unit systemd, reinicia e habilita o serviço.
- Off: o script desmonta o mount local, para a unit systemd e desabilita o serviço.
- Off não apaga a configuração do remote em `~/.config/rclone/rclone.conf`.

## Modo destrutivo

O prompt antigo de apagar todos os remotes foi removido do fluxo padrão. A recriação destrutiva só roda com opt-in explícito:

```bash
RCLONE_NUKE_ALL=true ./rclone_new_remotes.sh
```

Use esse modo apenas depois de baseline e plano de rollback.

## Fallback sem TTY

Quando o script roda sem terminal interativo, ele mantém todos os remotes ligados. Esse fallback evita desligamento acidental em execução não interativa.

## Validação mínima

```bash
bash -n rclone_new_remotes.sh
rclone about 'Google Drive:'
systemctl --user status rclone-google-drive.service --no-pager
```
