# Baseline de systemd do usuário

- Coletado em: 2026-05-20T09:10:54-03:00
- Backup bruto das units `rclone-*.service`: `/home/lucas/.local/state/rclone_new_remotes/baselines/20260520-084942/systemd-user/`

## Inventário de unit files

Comando executado:

```bash
systemctl --user list-unit-files 'rclone-*.service'
```

Resultado:

```text
UNIT FILE                                            STATE    PRESET
rclone-arquivos-e-cursos.service                     disabled enabled
rclone-comercial.service                             disabled enabled
rclone-documentos-compartilhados-organizejr.service  disabled enabled
rclone-filmes-lucas-aluno-colegiomaanaim-net.service disabled enabled
rclone-financeiro.service                            disabled enabled
rclone-google-drive.service                          enabled  enabled
rclone-google-photos.service                         disabled enabled
rclone-koofr-webdav-gdrive.service                   enabled  enabled
rclone-koofr.service                                 disabled enabled
rclone-lm-mobilidade-onedrive.service                disabled enabled
rclone-mega.service                                  disabled enabled
rclone-mej-lucas-organizejr-com.service              disabled enabled
rclone-onedrive.service                              disabled enabled
rclone-pcloud.service                                disabled enabled
rclone-presidencia-to-lucascamilo.service            disabled enabled
rclone-presidencia.service                           disabled enabled
rclone-psicologia-uneb-2026-1.service                disabled enabled
rclone-webdav-todos-remotes.service                  enabled  enabled
```

## Estado carregado antes da correção

Comando executado:

```bash
systemctl --user list-units 'rclone-*.service' --all --no-pager
```

Resultado antes da correção:

```text
rclone-google-drive.service         loaded activating start
rclone-koofr-webdav-gdrive.service  loaded active     running
rclone-webdav-todos-remotes.service loaded activating auto-restart
```

## Estado após reconexão e restart

Comandos executados:

```bash
systemctl --user restart rclone-google-drive.service rclone-webdav-todos-remotes.service
systemctl --user list-units 'rclone-*.service' --all --no-pager
```

Resultado após a correção:

```text
rclone-google-drive.service         loaded active running
rclone-koofr-webdav-gdrive.service  loaded active running
rclone-webdav-todos-remotes.service loaded active running
```

## Observações

- O serviço agregado `rclone-webdav-todos-remotes.service` foi reiniciado porque dependia do remote `Google Drive` saudável.
- Permanecem unidades falhas fora do escopo `rclone-*`: `hermes-gateway.service` e `webdav-koofr.service`.