# SCloudLab Composer

📦 Wall breaker with Docker

## Getting Started

Edit `config.yaml` and run `config.sh`.

## Caveats

A container may fail to communicate with the Internet because of some iptables issue: `sudo iptables -I INPUT -i docker0 -j ACCEPT` is a possible fix. (Accpect packets from interface `docker0`)

## Dev Planning

1. Create a master config file, and associated scripts to generate `xray/config.json` and `cert.env` with information from the master config file.
