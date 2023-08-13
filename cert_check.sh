#!/bin/bash

# Exit if no parameter is passed
if [[ $# != 1 ]]; then
    echo "Usage: $0 cert_path"
    exit 1
fi

# Set the certificate path
CERT_PATH=$1

# Check if the certificate exists
if [ ! -f $CERT_PATH/fullchain.crt ]; then
    echo "Certificate not found at $CERT_PATH"
    exit 1
fi

# Get the expiration date of the certificate
exp_date=$(date -d "$(openssl x509 -enddate -noout -in $CERT_PATH/fullchain.crt | awk -F = '{print $2}')" '+%s')

# Get the current date
now=$(date '+%s')

# Print the expiration date and the current date
echo "EXP: $(date -d @$exp_date '+%Y-%m-%d %H:%M:%S')"
echo "NOW: $(date -d @$now '+%Y-%m-%d %H:%M:%S')"

# Check if the certificate is expired
if test $exp_date -gt $now; then
    echo "✅ Certificate is OK"
else
    echo -e "❌ \033[0;31mCertificate is expired\033[0m"
    exit 1
fi