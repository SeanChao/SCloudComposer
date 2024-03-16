set -e

# Create a crontab job to update the certificate
# Certificate is updated monthly, using the cert.sh in the same directory
echo "Create a crontab job to update the certificate"
CRON_FILE=/etc/cron.d/cert_update
# Read the domain from yaml config
DOMAIN=$(yq '.domain' config.yaml)
echo "* * 1 * * root cd $(pwd) && /bin/bash $(pwd)/cert.sh ${DOMAIN} > cron_cert.log && docker-compose restart xray" | sudo tee ${CRON_FILE}
sudo systemctl status --no-pager cron | grep -q "Active: active" && echo "Cron is active" || echo "Cron is not active"
