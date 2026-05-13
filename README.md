# SCloudLab Composer

📦 Wall breaker with Docker

## Getting Started

Edit `config.yaml` and run `config.sh`.

## Caveats

A container may fail to communicate with the Internet because of some iptables issue: `sudo iptables -I INPUT -i docker0 -j ACCEPT` is a possible fix. (Accpect packets from interface `docker0`)

## REALITY Beta

The default TLS/Vision inbound remains on `443`. To run a parallel
REALITY/Vision beta inbound on `8443`, set `reality.enabled: true` in
`config.yaml`, run `./setup.sh reality-init` once to generate the local key pair
and shortIds, then run `./setup.sh 3` and restart `xray`. Use
`SKIP_CERT=1 ./setup.sh 3` when you only want to regenerate Xray config without
touching existing certificates.

The REALITY private key and assigned shortIds live only in local `config.yaml`.
Do not commit that file.

## Dev Planning

1. Create a master config file, and associated scripts to generate `xray/config.json` and `cert.env` with information from the master config file.
