# Relatório de ativação do Google Drive

- Executado em: 2026-05-20T09:10:54-03:00
- Remote alvo: `Google Drive:`
- Script operacional relacionado: `./rclone_new_remotes.sh`

## Sintoma inicial

- `rclone about 'Google Drive:'` falhava com `invalid_grant`
- `rclone-google-drive.service` estava em `activating/auto-restart`
- `rclone-webdav-todos-remotes.service` também estava em `activating/auto-restart`

## Ações executadas

1. backup bruto de `rclone.conf` e das units `rclone-*.service`
2. `rclone config reconnect 'Google Drive:'`
3. restart de:
   - `rclone-google-drive.service`
   - `rclone-webdav-todos-remotes.service`

## Resultado

### Saúde do remote

```bash
rclone about 'Google Drive:'
```

Resposta observada:

```text
Total:   5 TiB
Used:    42.147 GiB
Free:    4.958 TiB
Trashed: 9.081 GiB
Other:   1.360 GiB
```

### Saúde da unit do mount

```bash
systemctl --user status rclone-google-drive.service --no-pager
```

Resultado observado:

- `Loaded: loaded`
- `Active: active (running)`
- `ExecStart ... status=0/SUCCESS`

### Saúde do WebDAV agregado

```bash
systemctl --user status rclone-webdav-todos-remotes.service --no-pager
```

Resultado observado:

- `Loaded: loaded`
- `Active: active (running)`

### Evidência de mount funcional

O diretório montado `/home/lucas/Google Drive` voltou a listar conteúdo via filesystem local.

## Limites desta ativação

- Não houve mudança permanente no fluxo do script `rclone_new_remotes.sh`
- A correção foi operacional, não estrutural
- O próximo ciclo ainda deve tratar endurecimento do fluxo para evitar regressão futura