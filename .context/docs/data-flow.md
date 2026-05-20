# Data flow and integrations

## System inputs

### Static configuration in `rclone_new_remotes.sh`

O script recebe do próprio arquivo:

- nomes de contas e remotes;
- client IDs e client secrets OAuth;
- senhas obscurecidas para Mega, Koofr e WebDAV;
- endereços de mount e cache;
- parâmetros do WebDAV agregado.

### External runtime state

O comportamento final também depende de:

- `~/.config/rclone/rclone.conf`;
- disponibilidade de rede;
- sessão de navegador para autenticação interativa;
- `systemd --user` e units já existentes;
- diretórios locais em `/home/lucas`.

## Main execution pipeline

1. **Bootstrap local**
   - cria diretórios base de `systemd` e cache;
   - garante o alias manual de GVFS;
   - inicializa flags globais como `NEEDS_AUTH` e `WEBDAV_ALL_READY`.

2. **Configuração por remote**
   - percorre arrays de contas e remotes;
   - para cada item, chama `process_remote`;
   - dentro da função, consulta `rclone listremotes`;
   - se o remote faltar, executa `rclone config create` com parâmetros do provider.

3. **Autenticação manual quando necessário**
   - providers OAuth não são totalmente concluídos pelo script;
   - o operador recebe instrução explícita para rodar `rclone config reconnect "<remote>:"`.

4. **Provisionamento local de mount**
   - cria o diretório `/home/lucas/<Nome do Remote>`;
   - gera a unit `~/.config/systemd/user/rclone-<nome-sanitizado>.service`.

5. **Validação pós configuração**
   - OAuth: tenta `rclone about` e, no caso de Google Photos, `rclone lsd` como fallback;
   - senha/WebDAV: usa `rclone about`;
   - WebDAV agregado: recalcula depois da rodada de autenticação.

6. **Ativação operacional**
   - roda `systemctl --user daemon-reload`;
   - faz stop/start das units dos remotes;
   - habilita os serviços que subirem com sucesso.

## Persistent outputs

- entradas em `rclone.conf`;
- diretórios de mount em `/home/lucas/`;
- cache em `/home/lucas/.cache/rclone` e `/home/lucas/.cache/rclone-webdav-all`;
- arquivos `.service` em `~/.config/systemd/user`;
- arquivos TLS e autenticação do WebDAV agregado em `~/.config/rclone/`.

## External integrations

### `rclone`

É a integração central. O script delega a ele criação de remotes, reconexão OAuth, health-check e mounts.

### `systemd --user`

É o orquestrador de longa duração dos mounts. Sem ele, o script só faria configuração pontual.

### Browser based OAuth

Google Drive, OneDrive, Pcloud e Google Photos dependem de autorização interativa. O script prepara a configuração, mas o handshake final acontece fora do terminal.

### `openssl`

Usado no subsistema de TLS local do WebDAV agregado.

### Obsidian and Remotely Save reference code

`obsidian_profile_portability.py` e `remotely-save-src/` não trocam dados diretamente com o script principal. Eles compartilham domínio, não pipeline de execução.

## State management

Não existe banco de dados local do projeto. O estado fica espalhado entre:

- variáveis do script durante a execução;
- arquivos de configuração do `rclone`;
- units e estado do `systemd --user`;
- estrutura de diretórios local;
- artefatos de contexto em `.context/`.

## Operational choke points

- prompt destrutivo de recriação global;
- reconexão OAuth no meio de um fluxo que também mexe em outros remotes;
- deleção automática de alguns remotes com falha de login;
- reinício em massa de serviços ao final, mesmo quando o objetivo é validar só um remote.

## Data flow guidance for the next cycle

O próximo ciclo deve introduzir um baseline explícito antes de qualquer mutação e separar validação direcionada de Google Drive do fluxo global de reinício. Esse é o principal ponto para reduzir risco operacional.