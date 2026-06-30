#!/bin/bash

set -euo pipefail

compose() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

config_value() {
    yq -r "$1 // \"\"" config.yaml
}

config_array_json() {
    yq -o=json "$1 // []" config.yaml
}

# Function for installing dependencies
install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update
    sudo apt install -y curl wget cron jq openssl
    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
        chmod +x /usr/bin/yq
}

# Function for installing Docker if not already installed
install_docker() {
    echo "Installing Docker..."
    [ ! -f /usr/bin/docker ] && bash install-docker.sh
}

init_reality_config() {
    if [ ! -f config.yaml ]; then
        echo "config.yaml is missing. Copy config.yaml.example first."
        exit 1
    fi

    yq -i '.reality.enabled = true' config.yaml

    if [ -z "$(config_value '.reality.port')" ]; then
        yq -i '.reality.port = 8443' config.yaml
    fi

    if [ -z "$(config_value '.reality.vless_id')" ]; then
        yq -i '.reality.vless_id = .vless_id' config.yaml
    fi

    if [ -z "$(config_value '.reality.server_name')" ]; then
        # Avoid www.microsoft.com: its Akamai edge fails the REALITY handshake
        # relay. www.apple.com negotiates TLS 1.3 + X25519 and works reliably.
        yq -i '.reality.server_name = "www.apple.com"' config.yaml
    fi

    if [ -z "$(config_value '.reality.dest')" ]; then
        REALITY_SERVER_NAME=$(config_value '.reality.server_name')
        REALITY_DEST="${REALITY_SERVER_NAME}:443"
        REALITY_DEST="$REALITY_DEST" yq -i '.reality.dest = strenv(REALITY_DEST)' config.yaml
    fi

    if [ -z "$(config_value '.reality.private_key')" ] || [ -z "$(config_value '.reality.public_key')" ]; then
        echo "Generating REALITY x25519 key pair..."
        KEY_OUTPUT=$(compose run --rm --no-deps --entrypoint xray xray x25519)
        PRIVATE_KEY=$(printf '%s\n' "$KEY_OUTPUT" | awk -F': ' '/^Private key|^PrivateKey/ {print $2}')
        PUBLIC_KEY=$(printf '%s\n' "$KEY_OUTPUT" | awk -F': ' '/^Public key|^PublicKey|^Password/ {print $2}')

        if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
            echo "Failed to parse xray x25519 output:"
            printf '%s\n' "$KEY_OUTPUT"
            exit 1
        fi

        PRIVATE_KEY="$PRIVATE_KEY" yq -i '.reality.private_key = strenv(PRIVATE_KEY)' config.yaml
        PUBLIC_KEY="$PUBLIC_KEY" yq -i '.reality.public_key = strenv(PUBLIC_KEY)' config.yaml
    fi

    SHORT_ID_COUNT=$(config_value '.reality.short_id_count')
    SHORT_ID_COUNT=${SHORT_ID_COUNT:-10}
    EXISTING_SHORT_IDS=$(yq '.reality.short_ids // [] | length' config.yaml)

    if [ "$EXISTING_SHORT_IDS" -eq 0 ]; then
        echo "Generating ${SHORT_ID_COUNT} REALITY shortIds..."
        yq -i '.reality.short_ids = []' config.yaml
        for _ in $(seq 1 "$SHORT_ID_COUNT"); do
            SHORT_ID=$(openssl rand -hex 8)
            SHORT_ID="$SHORT_ID" yq -i '.reality.short_ids += [strenv(SHORT_ID)]' config.yaml
        done
    fi
}

# Function for applying configurations
apply_configs() {
    echo "Applying configurations..."
    DOMAIN=$(config_value '.domain')
    VLESS_ID=$(config_value '.vless_id')
    REALITY_ENABLED=$(config_value '.reality.enabled')
    REALITY_ENABLED=${REALITY_ENABLED:-false}

    if [ "$REALITY_ENABLED" = "true" ]; then
        init_reality_config
    fi

    REALITY_PORT=$(config_value '.reality.port')
    REALITY_PORT=${REALITY_PORT:-8443}
    REALITY_VLESS_ID=$(config_value '.reality.vless_id')
    REALITY_VLESS_ID=${REALITY_VLESS_ID:-$VLESS_ID}
    REALITY_PRIVATE_KEY=$(config_value '.reality.private_key')
    REALITY_SERVER_NAME=$(config_value '.reality.server_name')
    REALITY_DEST=$(config_value '.reality.dest')
    REALITY_SHORT_IDS=$(config_array_json '.reality.short_ids')

    jq \
        --arg vless_id "$VLESS_ID" \
        --arg reality_vless_id "$REALITY_VLESS_ID" \
        --arg reality_private_key "$REALITY_PRIVATE_KEY" \
        --arg reality_server_name "$REALITY_SERVER_NAME" \
        --arg reality_dest "$REALITY_DEST" \
        --argjson reality_port "$REALITY_PORT" \
        --argjson reality_short_ids "$REALITY_SHORT_IDS" \
        --argjson reality_enabled "$REALITY_ENABLED" \
        '
        .inbounds = (
          [.inbounds[] | select(.tag != "reality-beta")] +
          (
            if $reality_enabled then
              [{
                "port": $reality_port,
                "tag": "reality-beta",
                "protocol": "vless",
                "settings": {
                  "clients": [{
                    "id": $reality_vless_id,
                    "flow": "xtls-rprx-vision",
                    "email": "reality-beta"
                  }],
                  "decryption": "none"
                },
                "streamSettings": {
                  "network": "tcp",
                  "security": "reality",
                  "realitySettings": {
                    "show": false,
                    "dest": $reality_dest,
                    "serverNames": [$reality_server_name],
                    "privateKey": $reality_private_key,
                    "shortIds": $reality_short_ids
                  }
                },
                "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
              }]
            else
              []
            end
          )
        ) |
        .inbounds[0].settings.clients[0].id = $vless_id
        ' xray/config.json > xray/config_tmp.json && mv xray/config{_tmp,}.json

    if [ "${SKIP_CERT:-0}" != "1" ]; then
        bash ./cert.sh ${DOMAIN}
    fi
}

# Function for starting services and setting up maintenance tasks
start_services() {
    echo "Starting services..."
    compose up -d caddy xray
    echo "Setting up maintenance tasks..."
    bash cert_update.sh
}

# CLI Interface
case "$1" in
    1) install_dependencies ;;
    2) install_docker ;;
    3) apply_configs ;;
    4) start_services ;;
    5|reality-init) init_reality_config ;;
    all)
        install_dependencies
        install_docker
        apply_configs
        start_services
        ;;
    *)
        echo "Usage: $0 {1|2|3|4|all}"
        echo "1: Install dependencies"
        echo "2: Install Docker if not installed"
        echo "3: Apply configurations"
        echo "4: Start services and setup maintenance tasks"
        echo "5/reality-init: Generate persisted REALITY keys and shortIds in config.yaml"
        echo "all: Run all steps"
        ;;
esac
