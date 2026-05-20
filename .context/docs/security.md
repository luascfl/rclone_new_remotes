# Security and compliance notes

## Current security posture

A superfície de risco deste repositório é alta para um projeto pequeno, porque ele lida com:

- client IDs e client secrets de provedores OAuth;
- senhas obscurecidas para backends com autenticação por usuário/senha;
- arquivo separado de token GitHub;
- mounts que expõem conteúdo de múltiplas contas pessoais e organizacionais.

## Observed sensitive points

- `rclone_new_remotes.sh` contém segredos operacionais embutidos.
- `GITHUB_TOKEN.txt` existe na raiz do repositório local.
- o fluxo de recriação em massa pode afetar vários remotes se usado indevidamente.
- o script gera e reinicia serviços persistentes do usuário, então um erro tem efeito além do terminal atual.

## Documentation hygiene

- não copie segredos para `.context/docs/`;
- não registre tokens, senhas obscurecidas, client secrets ou paths privados completos em relatórios operacionais;
- quando precisar citar um remote sensível, prefira o nome lógico e omita valores de credencial.

## Operational safeguards required

1. criar baseline antes de qualquer mutação em `rclone.conf`;
2. evitar deleção automática por falha transitória de autenticação;
3. separar modo de validação direcionada do modo destrutivo de recriação global;
4. validar o status de apenas um remote alvo antes de reiniciar o conjunto inteiro;
5. manter rollback documentado para config e units `systemd --user`.

## Secret handling guidance

Estado atual observado:

- os segredos já estão presentes em arquivos locais;
- o `.gitignore` tenta ignorar vários nomes sensíveis;
- isso reduz exposição futura, mas não corrige material já escrito em arquivos rastreados ou compartilhados.

Direção recomendada para ciclos futuros:

- migrar segredos para arquivo local não versionado ou variáveis de ambiente;
- deixar no script apenas referências a variáveis obrigatórias;
- registrar checagem de presença das variáveis antes da execução.

## Validation commands with lower exposure

Prefira comandos que validem comportamento sem ecoar credenciais:

- `rclone listremotes`
- `rclone about 'Google Drive:'`
- `systemctl --user status 'rclone-google-drive.service' --no-pager`
- `journalctl --user -u 'rclone-google-drive.service' --since '10 minutes ago'`

## Compliance stance for this context

Não há framework formal de compliance documentado no repositório. O padrão mínimo deste contexto é proteção operacional, rastreabilidade e não propagação de segredos em artefatos de texto.