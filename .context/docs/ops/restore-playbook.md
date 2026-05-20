# Playbook de restore rápido

## Escopo

Este restore cobre o material salvo antes da reativação do remote `Google Drive`:

- backup bruto de `rclone.conf`
- backup das units `rclone-*.service`

Baseline usada nesta ativação:

- `/home/lucas/.local/state/rclone_new_remotes/baselines/20260520-084942/`

## Pré-condições

- sessão do usuário `lucas`
- acesso de escrita a `~/.config/rclone/`
- acesso de escrita a `~/.config/systemd/user/`

## Restore de `rclone.conf`

1. parar as units diretamente afetadas:

```bash
systemctl --user stop rclone-google-drive.service rclone-webdav-todos-remotes.service
```

2. restaurar o arquivo salvo:

```bash
cp /home/lucas/.local/state/rclone_new_remotes/baselines/20260520-084942/rclone.conf /home/lucas/.config/rclone/rclone.conf
```

## Restore das units `rclone-*.service`

1. restaurar os arquivos de unit do backup:

```bash
cp /home/lucas/.local/state/rclone_new_remotes/baselines/20260520-084942/systemd-user/rclone-*.service /home/lucas/.config/systemd/user/
```

2. recarregar o daemon do usuário:

```bash
systemctl --user daemon-reload
```

3. subir as units principais:

```bash
systemctl --user start rclone-google-drive.service rclone-webdav-todos-remotes.service
```

## Validação pós-restore

Rodar, nesta ordem:

```bash
rclone listremotes
rclone about 'Google Drive:'
systemctl --user status rclone-google-drive.service --no-pager
systemctl --user status rclone-webdav-todos-remotes.service --no-pager
systemctl --user list-units 'rclone-*.service' --all --no-pager
```

## Sinais de sucesso

- `Google Drive:` continua listado em `rclone listremotes`
- `rclone about 'Google Drive:'` responde sem `invalid_grant`
- `rclone-google-drive.service` fica `active (running)`
- `rclone-webdav-todos-remotes.service` fica `active (running)`

## Observação

Se o problema voltar a ser `invalid_grant`, o restore sozinho não renova token. Nesse caso o próximo passo operacional é repetir `rclone config reconnect 'Google Drive:'`.