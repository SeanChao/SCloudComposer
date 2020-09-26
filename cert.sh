#!/bin/bash

# Parse domain from shell param
if [[ $# != 1 ]]; then
    echo "Usage: $0 your-domain.com"
    exit 1
fi
domain=$1

# Install acme.sh
if [ ! -f ~/.acme.sh/acme.sh ]; then
    echo "acme.sh not installed, installing..."
    sudo apt install -y socat
    curl https://get.acme.sh | sh
fi

# Install
echo -e "Please make sure port 80 is not occupied by other programs"
echo -e "Install TLS certificate for \033[0;34m$domain\033[;0m"
~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256

mkdir -p ./trojan-crt
~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath ./trojan-crt/server.crt --keypath ./trojan-crt/server.key --ecc
