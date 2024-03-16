#!/bin/bash

# Function for installing dependencies
install_dependencies() {
    echo "Installing dependencies..."
    sudo apt update
    sudo apt install -y curl wget cron
    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
        chmod +x /usr/bin/yq
}

# Function for installing Docker if not already installed
install_docker() {
    echo "Installing Docker..."
    [ ! -f /usr/bin/docker ] && bash install-docker.sh
}

# Function for applying configurations
apply_configs() {
    echo "Applying configurations..."
    DOMAIN=$(yq '.domain' config.yaml)
    VLESS_ID=$(yq '.vless_id' config.yaml)
    jq --arg vless_id "$VLESS_ID" '.inbounds[0].settings.clients[0].id = $vless_id' xray/config.json > xray/config_tmp.json && mv xray/config{_tmp,}.json
    bash ./cert.sh ${DOMAIN}
}

# Function for starting services and setting up maintenance tasks
start_services() {
    echo "Starting services..."
    docker-compose up -d caddy xray
    echo "Setting up maintenance tasks..."
    bash cert_update.sh
}

# CLI Interface
case "$1" in
    1) install_dependencies ;;
    2) install_docker ;;
    3) apply_configs ;;
    4) start_services ;;
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
        echo "all: Run all steps"
        ;;
esac
