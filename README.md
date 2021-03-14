# SCloudLab Composer

📦 Wall breaker with docker

## Getting Started

Update `xray/config.json` with your specific config (including UUID and password).
Update `tg.env` with telegram proxy secret.

And Run!

> The script (`*.sh`) only serves as a hint of how to make things work. It's not intended to work  as expected everywhere. Please follow official guides to get yourself `docker` and TLS certificates.

```sh
./setup.sh
./install-docker.sh
# Get TLS certificate for your domain
./cert.sh your-domain
# Go!
docker-compose up --build -d
```

## Caveats

A container may fail to communicate with the Internet because of some iptables issue: `sudo iptables -I INPUT -i docker0 -j ACCEPT` is a possible fix. (Accpect packets from interface `docker0`)
