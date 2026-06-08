#!/bin/bash

# ==============================================================================
# Script de Orquestração Multi-Conta Completo do Rclone
# Autor: Gemini + Assistant
# Versão: 8.27
#
# Changelog V8.27:
# - Adiciona CLI explícita: --setup para fluxo completo, --manage para só gerenciar on/off, --help para ajuda.
#
# Changelog V8.26:
# - Adiciona modo RCLONE_REMOTE_MENU_ONLY=true para abrir só o menu on/off e aplicar systemd sem setup completo.
#
# Changelog V8.25:
# - Adiciona seletor interativo por TTY para ligar/desligar remotes com setas e espaço.
# - Remotes desligados têm o serviço systemd parado/desabilitado sem apagar a configuração do rclone.
#
# Changelog V8.24:
# - Google Drive direto agora usa VFS cache full e timeouts/retries explícitos para mount estável.
# - Registra alias manual da pasta de rede GVFS Koofr/GDrive sem usá-la como backend de automação.
#
# Changelog V8.23:
# - WebDAV agregado passou de vfs-cache-mode full para writes.
# - Corrige falha de leitura/sync em arquivos Google Docs/Sheets exportados (.docx/.xlsx) no Remotely Save.
#
# Changelog V8.21:
# - Adicionado remote combine "Todos Remotes" para WebDAV único de todos os remotes.
# - Adicionado serviço systemd dedicado para o WebDAV agregado.
#
# Changelog V8.20:
# - Adicionado Google Photos (CONTA 9) para lucascmcr@gmail.com.
#
# Changelog V8.19:
# - Adicionado provedor WebDAV (CONTA 8) para o Koofr/GDrive.
# ==============================================================================

# ==============================================================================
# --- Configuração do Mega (Automática, sem 2FA) ---
# ==============================================================================
MEGA_OBSCURED_PASS="WjonZ5wggDiO4GYmAdrsDgm3XMwF8Qc5FrIWXi15"
MEGA_USER="lucascamr107@gmail.com"
# ==============================================================================

# ==============================================================================
# --- CONFIGURAÇÃO DO KOOFR ---
# ==============================================================================
KOOFR_USER="lucascamr107@gmail.com"
KOOFR_OBSCURED_PASS="d65y1a3xc8avo9m7"
# ==============================================================================

# ==============================================================================
# --- CONFIGURAÇÃO DO WEBDAV ---
# ==============================================================================
WEBDAV_USER="lucascamr107@gmail.com"
WEBDAV_URL="https://app.koofr.net/dav/Google%20Drive/"
WEBDAV_OBSCURED_PASS="L_b_0-NrYXDDBb8g9A1KiMAcNrbz0hMdACA_FHyyk-4"
# ==============================================================================


# --- Cores para uma saída mais legível ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem Cor

# --- Diretórios Globais de Configuração ---
MOUNT_BASE_DIR="/home/lucas"
SYSTEMD_USER_DIR="${MOUNT_BASE_DIR}/.config/systemd/user"


# --- Alias manual da pasta de rede GVFS Koofr/GDrive ---
# Mantido apenas para navegação no gerenciador de arquivos. Para automação, use rclone mount.
SHARED_NETWORK_ALIAS_PATH="${MOUNT_BASE_DIR}/Koofr_GDrive_WebDAV"
SHARED_NETWORK_GVFS_PATH="/run/user/1000/gvfs/dav:host=app.koofr.net,ssl=true,user=lucascamr107%40gmail.com,prefix=%2Fdav/Google Drive"
# --- Configuração do WebDAV agregado (todos os remotes) ---
WEBDAV_ALL_ENABLED=true
WEBDAV_ALL_REMOTE_NAME="Todos Remotes"
WEBDAV_ALL_ADDR="127.0.0.1:8443"
WEBDAV_ALL_CACHE_DIR="${MOUNT_BASE_DIR}/.cache/rclone-webdav-all"
WEBDAV_ALL_SERVICE_NAME="rclone-webdav-todos-remotes.service"
WEBDAV_ALL_AUTH_FILE="${MOUNT_BASE_DIR}/.config/rclone/webdav-all-auth.env"
WEBDAV_ALL_HTPASSWD_FILE="${MOUNT_BASE_DIR}/.config/rclone/webdav-all.htpasswd"
WEBDAV_ALL_TLS_DIR="${MOUNT_BASE_DIR}/.config/rclone/webdav-all-tls"
WEBDAV_ALL_CERT_FILE="${WEBDAV_ALL_TLS_DIR}/cert.pem"
WEBDAV_ALL_KEY_FILE="${WEBDAV_ALL_TLS_DIR}/key.pem"
WEBDAV_ALL_CA_CERT_FILE="${WEBDAV_ALL_TLS_DIR}/ca-cert.pem"
WEBDAV_ALL_CA_KEY_FILE="${WEBDAV_ALL_TLS_DIR}/ca-key.pem"
WEBDAV_ALL_TLS_CA_NICKNAME="rclone-webdav-local-ca"
WEBDAV_ALL_TLS_CA_CN="Rclone Local WebDAV CA"
WEBDAV_ALL_TLS_CN="localhost"
WEBDAV_ALL_TLS_DAYS=825

# --- Função principal para processar um remote (configurar, criar pasta, etc.) ---
process_remote() {
    local remote_name="$1"
    local remote_type="$2" 
    local client_id="$3"
    local client_secret="$4"
    local account_email="$5"
    local provider="$6"  # google, onedrive, sharepoint, mega, koofr, pcloud, webdav, googlephotos
    
    local mount_point_path="${MOUNT_BASE_DIR}/${remote_name}"
    
    local service_name_sanitized=$(echo "$remote_name" | tr -c '[:alnum:]' '-' | tr '[:upper:]' '[:lower:]' | sed 's/--\+/-/g' | sed 's/^-//' | sed 's/-$//')
    local service_file_path="${SYSTEMD_USER_DIR}/rclone-${service_name_sanitized}.service"
    
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}Processando: '${remote_name}' (Conta: ${account_email})${NC}"
    
    # --- Parte 1: Configuração do Remote no Rclone ---
    if rclone listremotes | grep -q "^${remote_name}:$"; then
        echo -e "${GREEN}--> Configuração do remote já existe.${NC}"
    else
        echo -e "${YELLOW}--> Criando configuração do remote...${NC}"
        
        local rclone_command=""

        if [ "$provider" == "mega" ]; then
            rclone_command="rclone config create \"${remote_name}\" mega type=mega user=\"${MEGA_USER}\" pass=\"${MEGA_OBSCURED_PASS}\""
        
        elif [ "$provider" == "koofr" ]; then
            rclone_command="rclone config create \"${remote_name}\" koofr type=koofr provider=koofr user=\"${KOOFR_USER}\" pass=\"${KOOFR_OBSCURED_PASS}\""

        elif [ "$provider" == "pcloud" ]; then
            rclone_command="rclone config create \"${remote_name}\" pcloud"

        elif [ "$provider" == "webdav" ]; then
            if [ "$WEBDAV_OBSCURED_PASS" == "COLE_A_SENHA_OBSCURA_AQUI" ] || [ -z "$WEBDAV_OBSCURED_PASS" ]; then
                echo -e "${RED}--> ERRO: Variável WEBDAV_OBSCURED_PASS não definida.${NC}"
                return
            fi
            rclone_command="rclone config create \"${remote_name}\" webdav type=webdav url=\"${WEBDAV_URL}\" vendor=other user=\"${WEBDAV_USER}\" pass=\"${WEBDAV_OBSCURED_PASS}\""

        # ==================== INÍCIO DA MODIFICAÇÃO (V8.20) ====================
        elif [ "$provider" == "googlephotos" ]; then
            # Cria configuração básica do Google Photos. A autenticação será pedida depois.
            rclone_command="rclone config create \"${remote_name}\" \"google photos\""
        # ===================== FIM DA MODIFICAÇÃO (V8.20) ======================

        elif [ "$provider" == "google" ]; then
            if [ "$remote_type" == "drive" ]; then
                rclone_command="rclone config create \"${remote_name}\" drive client_id=\"${client_id}\" client_secret=\"${client_secret}\" scope=drive"
            else
                rclone_command="rclone config create \"${remote_name}\" drive client_id=\"${client_id}\" client_secret=\"${client_secret}\" scope=drive team_drive=\"${remote_type}\""
            fi

        elif [ "$provider" == "onedrive" ] || [ "$provider" == "sharepoint" ]; then
            rclone_command="rclone config create \"${remote_name}\" onedrive"
        fi
        
        # Bloco de execução unificado
        if [ -n "$rclone_command" ]; then
            eval "$rclone_command"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}--> Configuração inicial criada.${NC}"
                
                # Autenticação interativa necessária
                if [ "$provider" == "google" ] || [ "$provider" == "onedrive" ] || [ "$provider" == "sharepoint" ] || [ "$provider" == "pcloud" ] || [ "$provider" == "googlephotos" ]; then
                    echo -e "${RED}     ⚠️  AÇÃO NECESSÁRIA: Autorize este novo remote via navegador executando:${NC}"
                    echo -e "${YELLOW}        rclone config reconnect \"${remote_name}:\"${NC}"
                    NEEDS_AUTH=true
                fi
            else
                echo -e "${RED}--> Erro ao criar configuração. Pulando...${NC}"
                return
            fi
        fi
    fi

    # --- Parte 2: Criação da Pasta de Montagem Local ---
    if [ ! -d "$mount_point_path" ]; then
        echo -e "${YELLOW}--> Criando pasta de montagem em '${mount_point_path}'...${NC}"
        mkdir -p "$mount_point_path" && echo -e "${GREEN}--> Pasta criada.${NC}"
    fi

    # --- Parte 3: Criação do Arquivo de Serviço Systemd ---
    echo -e "${YELLOW}--> Criando/Atualizando arquivo de serviço systemd: '${service_file_path}'...${NC}"
    
    local extra_flags=""
    if [ "$provider" == "google" ]; then
        # Google Drive direto é o melhor mount geral para o Drive: API nativa, cache local e menos uma camada que Koofr/WebDAV.
        extra_flags="--vfs-cache-mode full --cache-dir ${MOUNT_BASE_DIR}/.cache/rclone --dir-cache-time 72h --vfs-read-chunk-size 8M --vfs-read-chunk-size-limit 256M --timeout 1h --contimeout 30s --retries 10 --retries-sleep 5s --low-level-retries 20"
    elif [ "$provider" == "onedrive" ] || [ "$provider" == "sharepoint" ]; then
        extra_flags="--vfs-cache-mode full --cache-dir ${MOUNT_BASE_DIR}/.cache/rclone --timeout 1h --contimeout 30s --retries 10 --retries-sleep 5s --low-level-retries 20"
    elif [ "$provider" == "googlephotos" ]; then
        # Google Photos geralmente é read-only no rclone para modificações, mas útil ter cache
        extra_flags="--vfs-cache-mode writes --cache-dir ${MOUNT_BASE_DIR}/.cache/rclone --timeout 1h --contimeout 30s --retries 10 --retries-sleep 5s --low-level-retries 20"
    elif [ "$provider" == "webdav" ]; then
        # PDFs no Obsidian fazem leitura aleatória; cache full evita arquivos abrirem como 0/0 em mounts WebDAV
        extra_flags="--vfs-cache-mode full --cache-dir ${MOUNT_BASE_DIR}/.cache/rclone --dir-cache-time 72h --vfs-read-chunk-size 8M --vfs-read-chunk-size-limit 256M --timeout 1h --contimeout 30s --retries 10 --retries-sleep 5s --low-level-retries 20"
    fi
    
    cat <<EOF > "$service_file_path"
[Unit]
Description=Montar ${remote_name} com rclone
After=network-online.target graphical-session.target
Wants=network-online.target

[Service]
Type=forking
ExecStart=/usr/bin/rclone mount "${remote_name}:" "${mount_point_path}" --daemon ${extra_flags}
ExecStop=/bin/fusermount -u "${mount_point_path}"
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
    echo -e "${GREEN}--> Arquivo .service criado/atualizado.${NC}"
}

ensure_webdav_all_auth() {
    if ! command -v openssl >/dev/null 2>&1; then
        echo -e "${RED}--> Erro: openssl não encontrado. Instale para gerar credenciais/tls do WebDAV.${NC}"
        return 1
    fi

    local auth_dir
    local apache_md5_hash

    auth_dir="$(dirname "${WEBDAV_ALL_AUTH_FILE}")"
    mkdir -p "${auth_dir}"
    chmod 700 "${auth_dir}"

    if [ ! -f "${WEBDAV_ALL_AUTH_FILE}" ]; then
        local generated_user
        local generated_pass

        generated_user="${USER:-lucas}"
        generated_pass="$(openssl rand -base64 48 | tr -d '\n' | tr '/+' '_-' | cut -c1-40)"

        cat <<EOF > "${WEBDAV_ALL_AUTH_FILE}"
WEBDAV_ALL_USER="${generated_user}"
WEBDAV_ALL_PASS="${generated_pass}"
EOF
        chmod 600 "${WEBDAV_ALL_AUTH_FILE}"
        echo -e "${GREEN}--> Credenciais WebDAV geradas em '${WEBDAV_ALL_AUTH_FILE}'.${NC}"
        echo -e "${YELLOW}--> Salve esse arquivo em local seguro. Sem ele você perde acesso ao WebDAV agregado.${NC}"
    fi

    # shellcheck disable=SC1090
    source "${WEBDAV_ALL_AUTH_FILE}"

    if [ -z "${WEBDAV_ALL_USER}" ] || [ -z "${WEBDAV_ALL_PASS}" ]; then
        echo -e "${RED}--> Erro: '${WEBDAV_ALL_AUTH_FILE}' está incompleto (usuário/senha).${NC}"
        return 1
    fi

    apache_md5_hash="$(openssl passwd -apr1 "${WEBDAV_ALL_PASS}")"
    if [ -z "${apache_md5_hash}" ]; then
        echo -e "${RED}--> Erro: falha ao gerar hash da senha WebDAV.${NC}"
        return 1
    fi

    printf '%s:%s\n' "${WEBDAV_ALL_USER}" "${apache_md5_hash}" > "${WEBDAV_ALL_HTPASSWD_FILE}"
    chmod 600 "${WEBDAV_ALL_AUTH_FILE}" "${WEBDAV_ALL_HTPASSWD_FILE}"
    return 0
}

ensure_webdav_all_tls() {
    if ! command -v openssl >/dev/null 2>&1; then
        echo -e "${RED}--> Erro: openssl não encontrado. Não é possível habilitar HTTPS no WebDAV agregado.${NC}"
        return 1
    fi

    mkdir -p "${WEBDAV_ALL_TLS_DIR}"
    chmod 700 "${WEBDAV_ALL_TLS_DIR}"

    if [ ! -f "${WEBDAV_ALL_CA_CERT_FILE}" ] || [ ! -f "${WEBDAV_ALL_CA_KEY_FILE}" ]; then
        echo -e "${YELLOW}--> Gerando CA local para WebDAV agregado...${NC}"
        openssl req -x509 -nodes -newkey rsa:4096 \
            -keyout "${WEBDAV_ALL_CA_KEY_FILE}" \
            -out "${WEBDAV_ALL_CA_CERT_FILE}" \
            -sha256 -days "${WEBDAV_ALL_TLS_DAYS}" \
            -subj "/CN=${WEBDAV_ALL_TLS_CA_CN}" \
            -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
            -addext "keyUsage=critical,keyCertSign,cRLSign" \
            -addext "subjectKeyIdentifier=hash" > /dev/null 2>&1

        if [ $? -ne 0 ]; then
            echo -e "${RED}--> Falha ao gerar CA local para WebDAV agregado.${NC}"
            return 1
        fi
    fi

    local regenerate_server_cert=false
    if [ ! -f "${WEBDAV_ALL_CERT_FILE}" ] || [ ! -f "${WEBDAV_ALL_KEY_FILE}" ]; then
        regenerate_server_cert=true
    elif ! openssl verify -CAfile "${WEBDAV_ALL_CA_CERT_FILE}" "${WEBDAV_ALL_CERT_FILE}" > /dev/null 2>&1; then
        regenerate_server_cert=true
    fi

    if [ "$regenerate_server_cert" = true ]; then
        echo -e "${YELLOW}--> Gerando certificado TLS assinado pela CA local...${NC}"
        openssl genrsa -out "${WEBDAV_ALL_KEY_FILE}" 4096 > /dev/null 2>&1 || return 1

        local cert_ext_file="${WEBDAV_ALL_TLS_DIR}/server-cert-ext.cnf"
        local cert_csr_file="${WEBDAV_ALL_TLS_DIR}/server-cert.csr"

        cat <<EOF > "${cert_ext_file}"
subjectAltName=DNS:localhost,IP:127.0.0.1
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
EOF

        openssl req -new -key "${WEBDAV_ALL_KEY_FILE}" -out "${cert_csr_file}" -subj "/CN=${WEBDAV_ALL_TLS_CN}" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}--> Falha ao gerar CSR do certificado WebDAV.${NC}"
            rm -f "${cert_ext_file}" "${cert_csr_file}"
            return 1
        fi

        openssl x509 -req -in "${cert_csr_file}" \
            -CA "${WEBDAV_ALL_CA_CERT_FILE}" \
            -CAkey "${WEBDAV_ALL_CA_KEY_FILE}" \
            -CAcreateserial \
            -out "${WEBDAV_ALL_CERT_FILE}" \
            -days "${WEBDAV_ALL_TLS_DAYS}" \
            -sha256 \
            -extfile "${cert_ext_file}" > /dev/null 2>&1

        rm -f "${cert_ext_file}" "${cert_csr_file}"
        if [ $? -ne 0 ]; then
            echo -e "${RED}--> Falha ao assinar certificado TLS do WebDAV agregado.${NC}"
            return 1
        fi
    fi

    chmod 600 "${WEBDAV_ALL_CA_KEY_FILE}" "${WEBDAV_ALL_KEY_FILE}"
    chmod 644 "${WEBDAV_ALL_CA_CERT_FILE}" "${WEBDAV_ALL_CERT_FILE}"
    return 0
}

ensure_webdav_all_browser_trust() {
    if ! command -v certutil >/dev/null 2>&1; then
        echo -e "${YELLOW}--> Aviso: certutil não encontrado. O navegador pode exibir alerta de certificado.${NC}"
        return 0
    fi

    local nss_db_dir="${HOME}/.pki/nssdb"
    mkdir -p "${nss_db_dir}"

    if [ ! -f "${nss_db_dir}/cert9.db" ]; then
        certutil -N -d "sql:${nss_db_dir}" --empty-password > /dev/null 2>&1
    fi

    certutil -d "sql:${nss_db_dir}" -D -n "${WEBDAV_ALL_TLS_CA_NICKNAME}" > /dev/null 2>&1 || true
    certutil -d "sql:${nss_db_dir}" -A -n "${WEBDAV_ALL_TLS_CA_NICKNAME}" -t "C,," -i "${WEBDAV_ALL_CA_CERT_FILE}" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}--> CA local instalada na trust store do navegador (NSS): ${WEBDAV_ALL_TLS_CA_NICKNAME}.${NC}"
    else
        echo -e "${YELLOW}--> Aviso: não foi possível instalar CA local no NSS. O navegador pode alertar certificado.${NC}"
    fi
}

build_combine_upstreams() {
    local existing_remotes="$1"
    local upstreams=""
    local remote_config
    local name
    local type

    for remote_config in "${ACTIVE_REMOTES_CONFIG[@]}"; do
        IFS='|' read -r name type <<< "$remote_config"
        if echo "$existing_remotes" | grep -Fqx "${name}:"; then
            upstreams+="\"${name}=${name}:\" "
        else
            echo -e "${YELLOW}--> Aviso: remote '${name}' não existe no rclone config e será ignorado no WebDAV agregado.${NC}" >&2
        fi
    done

    echo "${upstreams% }"
}

configure_webdav_all_remote() {
    if [ "$WEBDAV_ALL_ENABLED" != "true" ]; then
        echo -e "${YELLOW}--> WebDAV agregado desativado por configuração.${NC}"
        return
    fi

    local existing_remotes
    local upstreams

    existing_remotes="$(rclone listremotes)"
    upstreams="$(build_combine_upstreams "$existing_remotes")"

    if [ -z "$upstreams" ]; then
        echo -e "${RED}--> Erro: nenhum remote disponível para compor '${WEBDAV_ALL_REMOTE_NAME}'.${NC}"
        return
    fi

    echo -e "${YELLOW}--> Configurando remote combine '${WEBDAV_ALL_REMOTE_NAME}'...${NC}"
    if echo "$existing_remotes" | grep -Fqx "${WEBDAV_ALL_REMOTE_NAME}:"; then
        rclone config update "${WEBDAV_ALL_REMOTE_NAME}" type=combine upstreams="${upstreams}"
    else
        rclone config create "${WEBDAV_ALL_REMOTE_NAME}" combine upstreams="${upstreams}"
    fi

    if [ $? -eq 0 ]; then
        WEBDAV_ALL_READY=true
        echo -e "${GREEN}--> Remote combine '${WEBDAV_ALL_REMOTE_NAME}' pronto.${NC}"
    else
        echo -e "${RED}--> Falha ao configurar '${WEBDAV_ALL_REMOTE_NAME}'.${NC}"
    fi
}

configure_webdav_all_service() {
    if [ "$WEBDAV_ALL_ENABLED" != "true" ]; then
        return
    fi

    if [ "$WEBDAV_ALL_READY" != "true" ]; then
        echo -e "${YELLOW}--> WebDAV agregado não será publicado porque o remote combine não ficou pronto.${NC}"
        return
    fi

    if ! ensure_webdav_all_auth; then
        WEBDAV_ALL_READY=false
        return
    fi

    if ! ensure_webdav_all_tls; then
        WEBDAV_ALL_READY=false
        return
    fi

    ensure_webdav_all_browser_trust

    local service_file_path="${SYSTEMD_USER_DIR}/${WEBDAV_ALL_SERVICE_NAME}"
    local webdav_exec_start="ExecStart=/usr/bin/rclone serve webdav \"${WEBDAV_ALL_REMOTE_NAME}:\" --addr \"${WEBDAV_ALL_ADDR}\" --vfs-cache-mode writes --cache-dir \"${WEBDAV_ALL_CACHE_DIR}\" --vfs-read-chunk-size 8M --vfs-read-chunk-size-limit 256M --timeout 1h --contimeout 30s --retries 10 --retries-sleep 5s --low-level-retries 20 --server-read-timeout 5m --server-write-timeout 5m --cert \"${WEBDAV_ALL_CERT_FILE}\" --key \"${WEBDAV_ALL_KEY_FILE}\" --htpasswd \"${WEBDAV_ALL_HTPASSWD_FILE}\" --drive-skip-shortcuts --drive-pacer-min-sleep 10ms --log-level INFO"

    echo -e "${YELLOW}--> Criando/Atualizando serviço WebDAV agregado: '${service_file_path}'...${NC}"
    cat <<EOF > "$service_file_path"
[Unit]
Description=Servir todos os remotes via WebDAV HTTPS (rclone combine)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
${webdav_exec_start}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

    echo -e "${GREEN}--> Serviço WebDAV agregado HTTPS configurado.${NC}"
}

ensure_shared_network_alias() {
    if [ -L "${SHARED_NETWORK_ALIAS_PATH}" ]; then
        local current_target
        current_target="$(readlink "${SHARED_NETWORK_ALIAS_PATH}")"
        if [ "${current_target}" == "${SHARED_NETWORK_GVFS_PATH}" ]; then
            echo -e "${GREEN}--> Alias GVFS já configurado: ${SHARED_NETWORK_ALIAS_PATH}${NC}"
            return 0
        fi

        echo -e "${YELLOW}--> Atualizando alias GVFS: ${SHARED_NETWORK_ALIAS_PATH}${NC}"
        rm -f "${SHARED_NETWORK_ALIAS_PATH}"
    elif [ -e "${SHARED_NETWORK_ALIAS_PATH}" ]; then
        echo -e "${YELLOW}--> Aviso: ${SHARED_NETWORK_ALIAS_PATH} existe e não é symlink. Mantendo sem alterar.${NC}"
        return 0
    fi

    if [ -d "${SHARED_NETWORK_GVFS_PATH}" ]; then
        ln -s "${SHARED_NETWORK_GVFS_PATH}" "${SHARED_NETWORK_ALIAS_PATH}"
        echo -e "${GREEN}--> Alias GVFS criado: ${SHARED_NETWORK_ALIAS_PATH}${NC}"
    else
        echo -e "${YELLOW}--> GVFS Koofr/GDrive não está montado agora. Alias manual não foi criado.${NC}"
    fi
}

service_basename_for_remote() {
    local remote_name="$1"
    local service_name_sanitized

    service_name_sanitized=$(echo "$remote_name" | tr -c '[:alnum:]' '-' | tr '[:upper:]' '[:lower:]' | sed 's/--\+/-/g' | sed 's/^-//' | sed 's/-$//')
    printf 'rclone-%s.service\n' "${service_name_sanitized}"
}

remote_config_enabled() {
    local wanted="$1"
    local remote_config

    for remote_config in "${ACTIVE_REMOTES_CONFIG[@]}"; do
        if [ "$remote_config" == "$wanted" ]; then
            return 0
        fi
    done

    return 1
}

remote_service_should_start_enabled() {
    local remote_name="$1"
    local service_basename
    local service_file_path

    service_basename="$(service_basename_for_remote "$remote_name")"
    service_file_path="${SYSTEMD_USER_DIR}/${service_basename}"

    if systemctl --user is-active --quiet "$service_basename" 2>/dev/null; then
        return 0
    fi

    if systemctl --user is-enabled --quiet "$service_basename" 2>/dev/null; then
        return 0
    fi

    if [ ! -f "$service_file_path" ]; then
        return 0
    fi

    return 1
}

draw_remote_toggle_menu() {
    local cursor="$1"
    local count="${#ALL_REMOTES_CONFIG[@]}"
    local index
    local remote_config
    local name
    local type
    local marker
    local pointer

    tput clear >/dev/tty
    echo -e "${PURPLE}=================================================${NC}" >/dev/tty
    echo -e "${PURPLE}       Seletor interativo de remotes rclone       ${NC}" >/dev/tty
    echo -e "${PURPLE}=================================================${NC}" >/dev/tty
    echo "Use ↑/↓ para navegar, espaço para on/off, Enter para aplicar." >/dev/tty
    echo "Atalhos: a liga todos, n desliga todos, q cancela." >/dev/tty
    echo >/dev/tty

    for ((index = 0; index < count; index++)); do
        remote_config="${ALL_REMOTES_CONFIG[$index]}"
        IFS='|' read -r name type <<< "$remote_config"

        if [ "${REMOTE_TOGGLE_STATE[$index]}" -eq 1 ]; then
            marker="[x]"
        else
            marker="[ ]"
        fi

        if [ "$index" -eq "$cursor" ]; then
            pointer=">"
        else
            pointer=" "
        fi

        printf '%s %s %s\n' "$pointer" "$marker" "$name" >/dev/tty
    done
}

select_active_remotes_interactively() {
    ACTIVE_REMOTES_CONFIG=()
    INACTIVE_REMOTES_CONFIG=()

    if [ ! -t 0 ] || [ ! -t 1 ]; then
        echo -e "${YELLOW}--> Sem TTY interativo. Mantendo todos os remotes ligados.${NC}"
        ACTIVE_REMOTES_CONFIG=("${ALL_REMOTES_CONFIG[@]}")
        return 0
    fi

    local count="${#ALL_REMOTES_CONFIG[@]}"
    local cursor=0
    local key
    local index
    local remote_config
    local name
    local type

    REMOTE_TOGGLE_STATE=()
    for ((index = 0; index < count; index++)); do
        remote_config="${ALL_REMOTES_CONFIG[$index]}"
        IFS='|' read -r name type <<< "$remote_config"
        if remote_service_should_start_enabled "$name"; then
            REMOTE_TOGGLE_STATE[$index]=1
        else
            REMOTE_TOGGLE_STATE[$index]=0
        fi
    done

    while true; do
        draw_remote_toggle_menu "$cursor"
        IFS= read -rsn1 key </dev/tty

        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -rsn2 -t 0.1 key </dev/tty || true
            case "$key" in
                "[A")
                    if [ "$cursor" -gt 0 ]; then
                        cursor=$((cursor - 1))
                    else
                        cursor=$((count - 1))
                    fi
                    ;;
                "[B")
                    if [ "$cursor" -lt $((count - 1)) ]; then
                        cursor=$((cursor + 1))
                    else
                        cursor=0
                    fi
                    ;;
            esac
        elif [[ "$key" == " " ]]; then
            if [ "${REMOTE_TOGGLE_STATE[$cursor]}" -eq 1 ]; then
                REMOTE_TOGGLE_STATE[$cursor]=0
            else
                REMOTE_TOGGLE_STATE[$cursor]=1
            fi
        elif [[ "$key" == "a" ]] || [[ "$key" == "A" ]]; then
            for ((index = 0; index < count; index++)); do
                REMOTE_TOGGLE_STATE[$index]=1
            done
        elif [[ "$key" == "n" ]] || [[ "$key" == "N" ]]; then
            for ((index = 0; index < count; index++)); do
                REMOTE_TOGGLE_STATE[$index]=0
            done
        elif [[ "$key" == "q" ]] || [[ "$key" == "Q" ]]; then
            tput clear >/dev/tty
            echo -e "${YELLOW}Operação cancelada pelo usuário.${NC}" >/dev/tty
            exit 0
        elif [[ "$key" == "" ]]; then
            break
        fi
    done

    tput clear >/dev/tty
    for ((index = 0; index < count; index++)); do
        remote_config="${ALL_REMOTES_CONFIG[$index]}"
        if [ "${REMOTE_TOGGLE_STATE[$index]}" -eq 1 ]; then
            ACTIVE_REMOTES_CONFIG+=("$remote_config")
        else
            INACTIVE_REMOTES_CONFIG+=("$remote_config")
        fi
    done
}

disable_inactive_remote_services() {
    local remote_config
    local name
    local type
    local service_basename
    local mount_path

    for remote_config in "${INACTIVE_REMOTES_CONFIG[@]}"; do
        IFS='|' read -r name type <<< "$remote_config"
        service_basename="$(service_basename_for_remote "$name")"
        mount_path="${MOUNT_BASE_DIR}/${name}"

        echo -e "${YELLOW}--> Desligando '${name}' (${service_basename})...${NC}"
        fusermount -u "${mount_path}" 2>/dev/null || true
        systemctl --user stop "$service_basename" 2>/dev/null || true
        systemctl --user disable "$service_basename" 2>/dev/null || true
    done
}

activate_selected_remote_services_only() {
    local remote_config
    local name
    local type
    local service_basename
    local service_file_path
    local mount_path

    echo -e "${PURPLE}Aplicando seleção nos serviços systemd existentes...${NC}"
    systemctl --user daemon-reload

    for remote_config in "${ACTIVE_REMOTES_CONFIG[@]}"; do
        IFS='|' read -r name type <<< "$remote_config"
        service_basename="$(service_basename_for_remote "$name")"
        service_file_path="${SYSTEMD_USER_DIR}/${service_basename}"
        mount_path="${MOUNT_BASE_DIR}/${name}"

        if [ ! -f "$service_file_path" ]; then
            echo -e "${YELLOW}--> Serviço ausente para '${name}': ${service_basename}. Mantendo sem setup.${NC}"
            continue
        fi

        echo -e "${GREEN}--> Ligando '${name}' (${service_basename})...${NC}"
        fusermount -u "${mount_path}" 2>/dev/null || true
        systemctl --user stop "$service_basename" 2>/dev/null || true
        systemctl --user start "$service_basename"
        if [ $? -eq 0 ]; then
            systemctl --user enable "$service_basename" 2>/dev/null || true
        else
            echo -e "${RED}--> Falha ao iniciar '${service_basename}'.${NC}"
        fi
    done
}

print_help() {
    cat <<EOF
Uso:
  ./rclone_new_remotes.sh --manage
  ./rclone_new_remotes.sh --setup
  ./rclone_new_remotes.sh --help

Modos:
  --manage   Abre só o menu interativo on/off e aplica nos serviços systemd existentes.
             Não cria remotes, não valida tokens, não recria WebDAV agregado e não roda setup completo.

  --setup    Abre o menu interativo on/off e roda o setup completo apenas para os remotes ligados.
             Cria/atualiza remotes, valida autenticação, configura WebDAV agregado e reinicia serviços.

  --help     Mostra esta ajuda.

Atalhos do menu:
  ↑/↓        Navega pelos remotes.
  espaço     Alterna on/off.
  Enter      Aplica a seleção.
  a          Liga todos.
  n          Desliga todos.
  q          Cancela.

Modo destrutivo:
  RCLONE_NUKE_ALL=true ./rclone_new_remotes.sh --setup

  Use só depois de baseline e rollback. Por padrão, remotes desligados não são apagados.
EOF
}

RUN_MODE=""
case "${1:-}" in
    --manage)
        RUN_MODE="manage"
        ;;
    --setup)
        RUN_MODE="setup"
        ;;
    --help|-h|"")
        print_help
        exit 0
        ;;
    *)
        echo -e "${RED}Argumento inválido: $1${NC}" >&2
        echo >&2
        print_help >&2
        exit 2
        ;;
esac

if [ "$#" -gt 1 ]; then
    echo -e "${RED}Use apenas um modo por execução.${NC}" >&2
    echo >&2
    print_help >&2
    exit 2
fi


# --- Início da Execução do Script ---
echo -e "${PURPLE}================================================="
echo -e "    Iniciando Orquestração Multi-Conta do Rclone (v8.27)   "
echo -e "=================================================${NC}"
echo

mkdir -p "$SYSTEMD_USER_DIR"
mkdir -p "${MOUNT_BASE_DIR}/.cache/rclone"
if [ "$WEBDAV_ALL_ENABLED" == "true" ]; then
    mkdir -p "${WEBDAV_ALL_CACHE_DIR}"
fi
ensure_shared_network_alias
NEEDS_AUTH=false
WEBDAV_ALL_READY=false
#===============================================================================
# DEFINIÇÃO DAS CONTAS E REMOTES
#===============================================================================

# Segredos OAuth ficam fora do repositorio: ~/.config/rclone_new_remotes/secrets.env (chmod 600)
[ -f "$HOME/.config/rclone_new_remotes/secrets.env" ] && . "$HOME/.config/rclone_new_remotes/secrets.env"

# CONTA 1: lucascamr107@gmail.com (Google)
ACCOUNT1_EMAIL="lucascamr107@gmail.com"
ACCOUNT1_CLIENT_ID="431363687179-gj8vismqvlfvp1tpfi7u15sc1d8up11j.apps.googleusercontent.com"
ACCOUNT1_CLIENT_SECRET="${ACCOUNT1_CLIENT_SECRET:-}"
declare -a ACCOUNT1_REMOTES=(
    "Google Drive|drive" 
    "Psicologia UNEB 2026.1|0AArrk0Iye2qrUk9PVA"
    "Arquivos e cursos|0ACGm_fAH3wifUk9PVA"
    "Documentos compartilhados OrganizeJr|0ALoE6nS5fvZoUk9PVA"
    "presidencia to lucascamilo|0AGWzRjEm41y7Uk9PVA"
    "PRESIDENCIA|0AEhrr5gINS8xUk9PVA"
    "Filmes - Lucas aluno.colegiomaanaim.net|0ABpK_yu_MVpMUk9PVA"
    "MEJ - Lucas organizejr.com|0AMBhx8U51r7aUk9PVA"
)

# CONTA 2: lucascamilo@organizejr.com (Google)
ACCOUNT2_EMAIL="lucascamilo@organizejr.com"
ACCOUNT2_CLIENT_ID="35826664902-bnphhui5m3td0cm0eotcvhofk0f9ukar.apps.googleusercontent.com"
ACCOUNT2_CLIENT_SECRET="${ACCOUNT2_CLIENT_SECRET:-}"
declare -a ACCOUNT2_REMOTES=(
    "FINANCEIRO|0AJaqm3eP_TQ3Uk9PVA"
    "COMERCIAL|0AJafInZl-qqFUk9PVA"
)

# CONTA 3: lucas.carvalho@lmmobilidade.com.br (OneDrive Business)
ACCOUNT3_EMAIL="lucas.carvalho@lmmobilidade.com.br"
declare -a ACCOUNT3_REMOTES=(
    "LM Mobilidade OneDrive|business"
)

# CONTA 4: lucascamr107@gmail.com (OneDrive Pessoal)
ACCOUNT4_EMAIL="lucascamr107@gmail.com"
declare -a ACCOUNT4_REMOTES=(
    "OneDrive|personal"
)

# CONTA 5: Mega
ACCOUNT5_EMAIL="$MEGA_USER"
declare -a ACCOUNT5_REMOTES=( "Mega|personal" )

# CONTA 6: Koofr
ACCOUNT6_EMAIL="$KOOFR_USER"
declare -a ACCOUNT6_REMOTES=( "Koofr|personal" )

# CONTA 7: Pcloud
ACCOUNT7_EMAIL="lucascamr107@gmail.com"
declare -a ACCOUNT7_REMOTES=( "Pcloud|personal" )

# CONTA 8: Koofr WebDAV
ACCOUNT8_EMAIL="$WEBDAV_USER"
declare -a ACCOUNT8_REMOTES=( "Koofr WebDAV GDrive|personal" )

# CONTA 9: Google Photos (NOVO)
ACCOUNT9_EMAIL="lucascmcr@gmail.com"
declare -a ACCOUNT9_REMOTES=(
    "Google Photos|google photos"
)

# Lista com TODOS os remotes disponíveis para o menu on/off
ALL_REMOTES_CONFIG=("${ACCOUNT1_REMOTES[@]}" "${ACCOUNT2_REMOTES[@]}" "${ACCOUNT3_REMOTES[@]}" "${ACCOUNT4_REMOTES[@]}" "${ACCOUNT5_REMOTES[@]}" "${ACCOUNT6_REMOTES[@]}" "${ACCOUNT7_REMOTES[@]}" "${ACCOUNT8_REMOTES[@]}" "${ACCOUNT9_REMOTES[@]}")

select_active_remotes_interactively
disable_inactive_remote_services
if [ "$RUN_MODE" == "manage" ]; then
    activate_selected_remote_services_only
    echo
    echo -e "${GREEN}Menu on/off aplicado sem executar setup completo.${NC}"
    exit 0
fi


if [ "${RCLONE_NUKE_ALL:-false}" == "true" ]; then
    echo -e "${PURPLE}RCLONE_NUKE_ALL=true detectado. Deletando todas as configurações de remote...${NC}"
    for remote_config in "${ALL_REMOTES_CONFIG[@]}"; do
        IFS='|' read -r name type <<< "$remote_config"
        echo -e " - Deletando ${name}..."
        rclone config delete "$name" > /dev/null 2>&1
    done
    echo -e " - Deletando ${WEBDAV_ALL_REMOTE_NAME}..."
    rclone config delete "${WEBDAV_ALL_REMOTE_NAME}" > /dev/null 2>&1
    rm -f "${SYSTEMD_USER_DIR}/${WEBDAV_ALL_SERVICE_NAME}"
    echo -e "${GREEN}Limpeza concluída.${NC}"
    echo
else
    echo -e "${GREEN}Sem recriação destrutiva. Use RCLONE_NUKE_ALL=true apenas com baseline e rollback.${NC}"
    echo
fi

# --- Início do Processamento de Contas ---

echo -e "${CYAN}Processando conta: lucascamr107@gmail.com (Drive)${NC}"
for remote_config in "${ACCOUNT1_REMOTES[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    if remote_config_enabled "$remote_config"; then
        process_remote "$name" "$type" "$ACCOUNT1_CLIENT_ID" "$ACCOUNT1_CLIENT_SECRET" "$ACCOUNT1_EMAIL" "google"
    fi
done

echo -e "\n${CYAN}Processando conta: lucascamilo@organizejr.com${NC}"
for remote_config in "${ACCOUNT2_REMOTES[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    if remote_config_enabled "$remote_config"; then
        process_remote "$name" "$type" "$ACCOUNT2_CLIENT_ID" "$ACCOUNT2_CLIENT_SECRET" "$ACCOUNT2_EMAIL" "google"
    fi
done

echo -e "\n${CYAN}Processando contas OneDrive...${NC}"
for remote_config in "${ACCOUNT3_REMOTES[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    if remote_config_enabled "$remote_config"; then
        process_remote "$name" "$type" "" "" "$ACCOUNT3_EMAIL" "onedrive"
    fi
done
for remote_config in "${ACCOUNT4_REMOTES[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    if remote_config_enabled "$remote_config"; then
        process_remote "$name" "$type" "" "" "$ACCOUNT4_EMAIL" "onedrive"
    fi
done

echo -e "\n${CYAN}Processando Mega, Koofr, Pcloud e WebDAV...${NC}"
if remote_config_enabled "Mega|personal"; then
    process_remote "Mega" "personal" "" "" "$ACCOUNT5_EMAIL" "mega"
fi
if remote_config_enabled "Koofr|personal"; then
    process_remote "Koofr" "personal" "" "" "$ACCOUNT6_EMAIL" "koofr"
fi
if remote_config_enabled "Pcloud|personal"; then
    process_remote "Pcloud" "personal" "" "" "$ACCOUNT7_EMAIL" "pcloud"
fi
if remote_config_enabled "Koofr WebDAV GDrive|personal"; then
    process_remote "Koofr WebDAV GDrive" "personal" "" "" "$ACCOUNT8_EMAIL" "webdav"
fi

echo -e "\n${CYAN}Processando conta: lucascmcr@gmail.com (Google Photos)${NC}"
for remote_config in "${ACCOUNT9_REMOTES[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    if remote_config_enabled "$remote_config"; then
        process_remote "$name" "$type" "" "" "$ACCOUNT9_EMAIL" "googlephotos"
    fi
done

if [ "${#ACTIVE_REMOTES_CONFIG[@]}" -gt 0 ]; then
    echo -e "\n${CYAN}Configurando WebDAV agregado (remotes ligados)...${NC}"
    configure_webdav_all_remote
    configure_webdav_all_service
else
    echo -e "\n${YELLOW}Nenhum remote ligado. WebDAV agregado não será configurado.${NC}"
fi


# --- Resumo Final e Verificações ---
echo
echo -e "${PURPLE}================================================="
echo -e "           Configuração de Remotes Concluída             "
echo -e "=================================================${NC}"

if [ "$NEEDS_AUTH" = true ]; then
    echo
    echo -e "${YELLOW}Lembrete: Alguns remotes precisam de configuração/autorização.${NC}"
fi

# --- Verificação de Autenticação (Saúde dos Tokens) ---
echo
echo -e "${PURPLE}================================================="
echo -e "     Verificando Saúde da Autenticação (Tokens e Login)    "
echo -e "=================================================${NC}"
GLOBAL_AUTH_FAILED=false

# --- Verificação OAuth (Google / OneDrive / Pcloud / Photos) ---
echo -e "${CYAN}Verificando Tokens OAuth (Google/OneDrive/Pcloud/Photos)...${NC}"
# Adicionando ACCOUNT9 na lista de verificação OAuth
ALL_OAUTH_REMOTES=("${ACCOUNT1_REMOTES[@]}" "${ACCOUNT2_REMOTES[@]}" "${ACCOUNT3_REMOTES[@]}" "${ACCOUNT4_REMOTES[@]}" "${ACCOUNT7_REMOTES[@]}" "${ACCOUNT9_REMOTES[@]}")

for remote_config in "${ALL_OAUTH_REMOTES[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    if ! remote_config_enabled "$remote_config"; then
        continue
    fi
    echo -e "${CYAN}--> Verificando '${name}'...${NC}"
    
    if rclone about "${name}:" > /dev/null 2>&1; then
        echo -e "${GREEN}      Token OK.${NC}"
    else
        # Google Photos as vezes falha no 'about', então tentamos um 'lsd' simples
        if [ "$type" == "google photos" ]; then
             if rclone lsd "${name}:" --max-depth 1 > /dev/null 2>&1; then
                 echo -e "${GREEN}      Token OK (Verificado via lista).${NC}"
                 continue
             fi
        fi

        echo -e "${RED}      FALHA NO TOKEN!${NC}"
        echo -e "${YELLOW}      Tentando reconexão interativa para '${name}'...${NC}"
        
        rclone config reconnect "${name}:"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}      Reconexão bem-sucedida para '${name}'.${NC}"
        else
            echo -e "${RED}      FALHA na reconexão interativa para '${name}'.${NC}"
            GLOBAL_AUTH_FAILED=true
        fi
    fi
done

# --- Verificação Login com Senha ---
echo
echo -e "${CYAN}Verificando Login (Mega/Koofr/WebDAV)...${NC}"
ALL_PASS_REMOTES=("${ACCOUNT5_REMOTES[@]}" "${ACCOUNT6_REMOTES[@]}" "${ACCOUNT8_REMOTES[@]}")

for remote_config in "${ALL_PASS_REMOTES[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    if ! remote_config_enabled "$remote_config"; then
        continue
    fi
    echo -e "${CYAN}--> Verificando '${name}'...${NC}"
    if rclone about "${name}:" > /dev/null 2>&1; then
        echo -e "${GREEN}      Login OK.${NC}"
    else
        echo -e "${RED}      FALHA NO LOGIN DO ${name}! Deletando remote.${NC}"
        rclone config delete "${name}" > /dev/null 2>&1
        GLOBAL_AUTH_FAILED=true
    fi
done


if [ "$WEBDAV_ALL_ENABLED" == "true" ] && [ "${#ACTIVE_REMOTES_CONFIG[@]}" -gt 0 ]; then
    echo -e "\n${CYAN}Revalidando WebDAV agregado após checagens de autenticação...${NC}"
    WEBDAV_ALL_READY=false
    configure_webdav_all_remote
    configure_webdav_all_service
fi
# --- Ativação de Todos os Serviços ---
echo
echo -e "${PURPLE}Ativando e/ou reiniciando os serviços systemd ligados...${NC}"
systemctl --user daemon-reload

for remote_config in "${ACTIVE_REMOTES_CONFIG[@]}"; do
    IFS='|' read -r name type <<< "$remote_config"
    service_basename="$(service_basename_for_remote "$name")"
    mount_path="${MOUNT_BASE_DIR}/${name}"
    
    if [ -f "${SYSTEMD_USER_DIR}/${service_basename}" ]; then
        echo -e "     - Reiniciando ${service_basename}..."
        fusermount -u "${mount_path}" 2>/dev/null
        systemctl --user stop "$service_basename" 2>/dev/null
        systemctl --user start "$service_basename"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}       Sucesso!${NC}"
            systemctl --user enable "$service_basename" 2>/dev/null
        else
            echo -e "${RED}       Falha ao iniciar.${NC}"
        fi
    fi
done

if [ "$WEBDAV_ALL_ENABLED" == "true" ] && [ "$WEBDAV_ALL_READY" == "true" ] && [ -f "${SYSTEMD_USER_DIR}/${WEBDAV_ALL_SERVICE_NAME}" ]; then
    echo -e "     - Reiniciando ${WEBDAV_ALL_SERVICE_NAME}..."
    systemctl --user stop "${WEBDAV_ALL_SERVICE_NAME}" 2>/dev/null
    systemctl --user start "${WEBDAV_ALL_SERVICE_NAME}"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}       Sucesso (WebDAV agregado)!${NC}"
        systemctl --user enable "${WEBDAV_ALL_SERVICE_NAME}" 2>/dev/null
    else
        echo -e "${RED}       Falha ao iniciar WebDAV agregado.${NC}"
    fi
elif [ "$WEBDAV_ALL_ENABLED" == "true" ]; then
    echo -e "${YELLOW}     - Desligando ${WEBDAV_ALL_SERVICE_NAME} porque o WebDAV agregado não está pronto ou não há remotes ligados.${NC}"
    systemctl --user stop "${WEBDAV_ALL_SERVICE_NAME}" 2>/dev/null || true
    systemctl --user disable "${WEBDAV_ALL_SERVICE_NAME}" 2>/dev/null || true
fi

echo
echo -e "${GREEN}Processo concluído.${NC}"
echo -e "${CYAN}WebDAV agregado HTTPS: ${WEBDAV_ALL_REMOTE_NAME} em https://${WEBDAV_ALL_ADDR}${NC}"
echo -e "${CYAN}Credenciais salvas em: ${WEBDAV_ALL_AUTH_FILE}${NC}"
echo -e "${CYAN}Arquivo htpasswd: ${WEBDAV_ALL_HTPASSWD_FILE}${NC}"
echo -e "${CYAN}CA local: ${WEBDAV_ALL_CA_CERT_FILE}${NC}"
echo -e "${CYAN}Se o Chrome estiver aberto, feche e abra novamente para recarregar a trust store.${NC}"
echo
