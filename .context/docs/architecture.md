# Architecture notes

## High level architecture

O repositório não é uma aplicação única. Ele é um conjunto de automações locais em torno de um fluxo operacional principal.

1. `rclone_new_remotes.sh` concentra a orquestração de infraestrutura pessoal.
2. `systemd --user` sustenta os mounts persistentes gerados pelo script.
3. `~/.config/rclone/rclone.conf` guarda o estado real dos remotes.
4. `obsidian_profile_portability.py` resolve um problema lateral de portabilidade do Obsidian.
5. `remotely-save-src/` serve como base de referência para integrações com armazenamento remoto, sem ser o entrypoint do ciclo atual.

## Key components

### `rclone_new_remotes.sh`

Responsabilidades principais:

- declarar contas, remotes e provedores;
- criar remotes `rclone config create` quando ausentes;
- orientar autenticação interativa para provedores OAuth;
- gerar arquivos `systemd` por remote;
- subir mounts com flags específicas por provedor;
- validar tokens e logins depois da configuração;
- manter um WebDAV agregado para todos os remotes;
- reiniciar os serviços ao final do fluxo.

### WebDAV agregado

O script mantém um remote `combine` e um serviço dedicado `rclone-webdav-todos-remotes.service`. Esse bloco é um subsistema próprio porque depende da saúde dos remotes individuais e adiciona TLS, credenciais locais e cache dedicado.

### Alias GVFS manual

O caminho GVFS de Koofr/Google Drive é preservado só para navegação manual. O comentário do script já deixa claro que automação deve preferir `rclone mount`, não o backend GVFS.

### `obsidian_profile_portability.py`

É um utilitário separado. Ele exporta, aplica e verifica configuração do Obsidian entre instalações `snap`, `deb` e Windows. Ele compartilha o mesmo domínio operacional do usuário, mas não participa do fluxo de mount do `rclone`.

### `remotely-save-src/`

É um subtree vendorizado do plugin Remotely Save. Hoje ele funciona como referência e eventual área de integração futura. Mudanças nele têm custo maior porque envolvem build Node/TypeScript e suíte própria de testes.

## Data flow between components

1. O script parte de constantes locais e do estado atual do `rclone`.
2. Para cada remote, decide entre reutilizar configuração existente ou criar uma nova.
3. Em seguida garante diretório de mount e gera uma unit `systemd --user` correspondente.
4. Depois executa checagens de autenticação com `rclone about` ou `rclone lsd`.
5. Por fim recarrega o daemon do usuário e reinicia os serviços dos mounts.
6. Se o WebDAV agregado estiver habilitado, ele é recalculado depois das checagens de saúde.

## Design patterns in practice

- Orquestração imperativa centralizada em um único script.
- Função genérica `process_remote` para padronizar criação, mount e unit por provider.
- Configuração por dados, com arrays de contas/remotes definindo quase todo o comportamento.
- Pós validação global antes da etapa final de ativação dos serviços.

## Technology decisions and rationale

- Bash foi escolhido para colar `rclone`, `systemctl --user`, `fusermount` e `openssl` sem camadas extras.
- `systemd --user` oferece persistência melhor que sessões manuais de mount.
- `rclone mount` com `--vfs-cache-mode full` foi priorizado para Google Drive direto e WebDAV por estabilidade de leitura aleatória.
- O subtree `remotely-save-src` é mantido como código de referência, em vez de reimplementar a lógica do plugin no script operacional.

## Current architectural risks

- O script mistura configuração, provisão, autenticação, validação e ativação final em um fluxo só.
- O prompt de “nuke” pode levar a deleção ampla se usado fora de contexto.
- Credenciais e client secrets aparecem em arquivos locais, o que aumenta superfície de risco.
- Falhas transitórias de autenticação hoje podem levar a comportamentos agressivos para alguns provedores.

## What should stay stable

- Os nomes dos remotes já em uso.
- O mapeamento entre remote, mount point e unit `systemd`.
- A distinção entre alias GVFS manual e backend real de automação.
- O papel do WebDAV agregado como derivado dos remotes individuais, nunca como fonte de verdade.