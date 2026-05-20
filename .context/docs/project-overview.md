# Project overview

## Objetivo do repositório

Este repositório é um workspace pessoal de automação local para `rclone` com suporte ao Obsidian. O fluxo operacional principal está em `rclone_new_remotes.sh`, que cria e valida remotes, gera services `systemd --user` e reinicia mounts. O utilitário `obsidian_profile_portability.py` é separado e cobre exportação, aplicação e verificação de configuração do Obsidian.

## Pontos de entrada reais

- `./rclone_new_remotes.sh`  
  Entrypoint do ciclo operacional atual, incluindo criação de remotes, verificação de autenticação e reinício de services.
- `./obsidian_profile_portability.py`  
  Utilitário Python para portabilidade de perfil do Obsidian entre instalações.
- `./remotely-save-src/`  
  Subtree vendorizado, fora do escopo principal enquanto a story não pedir alteração nele.

## Escopo oficial do ciclo Ralph atual

- Curadoria de contexto em `./.context/docs/`.
- Planejamento em `./.context/docs/planning_gsd/`.
- Stories e quality gates em `./.context/prd_ralph/prd.json`.

## Riscos operacionais imediatos

1. **Modo destrutivo de recriação global**  
   Em `./rclone_new_remotes.sh` existe prompt de exclusão total (`Apagar e recriar tudo? (s/n)`), que remove remotes antes de recriar.
2. **Recuperação limitada sem baseline**  
   Sem snapshot prévio de remotes e services, uma falha durante reconfiguração dificulta rollback rápido.
3. **Impacto amplo em services**  
   O script reinicia múltiplos services `systemd --user`; validar apenas um remote exige fluxo direcionado para evitar regressão.
4. **Segredos no código operacional**  
   O script contém dados sensíveis de configuração local. A documentação oficial deve registrar riscos e procedimentos, nunca os segredos.

## Regras de documentação deste projeto

- Não registrar credenciais, tokens, `client_secret` ou senhas obscurecidas em `.context/docs/`.
- Sempre referenciar caminhos reais do repositório para facilitar execução e auditoria local.
- Tratar `README.md` de raiz como opcional no estado atual do repo.

## Próximo encadeamento recomendado

1. S2: gerar baseline de `rclone.conf`, `rclone listremotes` e units `systemd --user`.
2. S3: definir execução segura para validar apenas `Google Drive` sem nuke global.
3. S4: validar remote alvo e registrar evidências objetivas.
4. S5: fechar com rollback consolidado e checklist contínuo.
