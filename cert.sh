#!/bin/bash
set -e

# Parse domain from shell param
if [[ $# < 1 ]]; then
    echo "Usage: $0 your-domain.com [acme-issue-args]"
    exit 1
fi
domain=$1
acme_issue_args=${2:-""}

# Install acme.sh
ACME=~/.acme.sh/acme.sh
if [ ! -f $ACME ]; then
    echo "acme.sh not installed, installing..."
    sudo apt install -y socat
    curl https://get.acme.sh | sh
else
    $ACME --upgrade
fi

# Install
echo -e "Install TLS certificate for \033[0;34m$domain\033[;0m"
set -o allexport; source cert.env; set +o allexport

$ACME --register-account -m ${ZERO_SSL_EMAIL}
$ACME --issue -d ${domain} -k ec-256 --dns dns_cf --force ${acme_issue_args}

CERT_DIR=./cert
mkdir -p ${CERT_DIR}
$ACME --installcert -d ${domain} --fullchainpath ${CERT_DIR}/fullchain.crt --keypath ${CERT_DIR}/private.key --ecc
