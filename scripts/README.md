# Server setup scripts

This directory contains server-side helper scripts.

## `setup-packages.sh`

Installs the base packages needed on the server.

It installs:

- Docker Engine
- Docker Compose plugin
- Go
- git
- make
- python3
- curl, ca-certificates, and gnupg

## Usage

Run on the server:

```bash
chmod +x scripts/setup-packages.sh
sudo scripts/setup-packages.sh
```

Optional environment variables:

```bash
sudo GO_VERSION=1.25.0 scripts/setup-packages.sh
sudo INSTALL_PYTHON3=0 scripts/setup-packages.sh
```

The script also adds the sudo user to the `docker` group.
After it finishes, log out and log back in before using `docker` without `sudo`.

## Verify

```bash
docker --version
docker compose version
go version
git --version
make --version
python3 --version
```

## `setup-caddy.sh`

Installs and configures Caddy for this ONIX setup.
It also installs Go so the Beckn app can be built on the server.

It creates six public sites:

- `baptest.remiges.tech`
- `bpptest.remiges.tech`
- `bapapp.remiges.tech`
- `bppapp.remiges.tech`
- `shop.remiges.tech`
- `storeadmin.remiges.tech`

And proxies these paths:

### BAP

All requests for `baptest.remiges.tech` are proxied to `127.0.0.1:8081`.

### BPP

All requests for `bpptest.remiges.tech` are proxied to `127.0.0.1:8082`.

### BAP app

All requests for `bapapp.remiges.tech` are proxied to `127.0.0.1:8083`.

### BPP app

All requests for `bppapp.remiges.tech` are proxied to `127.0.0.1:8080`.

### Frontend

Requests for `shop.remiges.tech` are routed as follows:

- `/api/*` is proxied to `127.0.0.1:8083`
- `/health` is proxied to `127.0.0.1:8083`
- all other paths are proxied to `127.0.0.1:3000`

The `/api/*` path is forwarded to the BAP app with the same URL path.

### BPP frontend

Requests for `storeadmin.remiges.tech` are routed as follows:

- `/api/*` is proxied to `127.0.0.1:8080`
- `/health` is proxied to `127.0.0.1:8080`
- all other paths are proxied to `127.0.0.1:3001`

The `/api/*` path is forwarded to the BPP app with the same URL path.

This means these internet-facing URLs will work after DNS and TLS are ready:

- `https://baptest.remiges.tech/bap/receiver/on_select`
- `https://baptest.remiges.tech/bap/receiver/on_init`
- `https://baptest.remiges.tech/bap/caller/discover`
- `https://bpptest.remiges.tech/bpp/caller/publish`
- `https://bpptest.remiges.tech/bpp/caller/on_select`
- `https://bpptest.remiges.tech/bpp/receiver/select`
- `https://bapapp.remiges.tech/api/webhook`
- `https://bppapp.remiges.tech/api/webhook`
- `https://shop.remiges.tech`
- `https://shop.remiges.tech/api/...`
- `https://shop.remiges.tech/health`

## Usage

Run on the server:

```bash
chmod +x scripts/setup-caddy.sh
sudo scripts/setup-caddy.sh
```

Optional environment variables:

```bash
sudo CADDY_EMAIL=ops@remiges.tech scripts/setup-caddy.sh
sudo GO_VERSION=1.25.0 scripts/setup-caddy.sh
```

You can also override domains or upstreams:

```bash
sudo \
  BAP_DOMAIN=baptest.remiges.tech \
  BPP_DOMAIN=bpptest.remiges.tech \
  BAPAPP_DOMAIN=bapapp.remiges.tech \
  BPPAPP_DOMAIN=bppapp.remiges.tech \
  FRONTEND_DOMAIN=shop.remiges.tech \
  BPP_FRONTEND_DOMAIN=storeadmin.remiges.tech \
  BAP_UPSTREAM=127.0.0.1:8081 \
  BPP_UPSTREAM=127.0.0.1:8082 \
  BAPAPP_UPSTREAM=127.0.0.1:8083 \
  BPPAPP_UPSTREAM=127.0.0.1:8080 \
  FRONTEND_UPSTREAM=127.0.0.1:3000 \
  BPP_FRONTEND_UPSTREAM=127.0.0.1:3001 \
  GO_VERSION=1.25.0 \
  scripts/setup-caddy.sh
```

## Prerequisites

Before running the script, make sure:

- `scripts/setup-packages.sh` has already been run
- DNS for `baptest.remiges.tech` points to the server
- DNS for `bpptest.remiges.tech` points to the server
- DNS for `bapapp.remiges.tech` points to the server
- DNS for `bppapp.remiges.tech` points to the server
- DNS for `shop.remiges.tech` points to the server
- DNS for `storeadmin.remiges.tech` points to the server
- ports `80` and `443` are open in Lightsail
- Docker stack is running on ports `8081` and `8082`
- `bapapp` is listening on `127.0.0.1:8083`
- `bppapp` is listening on `127.0.0.1:8080`
- `frontend` is listening on `127.0.0.1:3000`
- `bpp-frontend` is listening on `127.0.0.1:3001`
- `bapapp` is reachable on `127.0.0.1:8083` for `/api/*` from the frontend domain
- `bppapp` is reachable on `127.0.0.1:8080` for `/api/*` from the BPP frontend domain

## Verify

```bash
go version
curl -I https://baptest.remiges.tech
curl -I https://bpptest.remiges.tech
curl -I https://bapapp.remiges.tech
curl -I https://bppapp.remiges.tech
curl -I https://shop.remiges.tech
curl -I https://shop.remiges.tech/health
curl -I https://storeadmin.remiges.tech
curl -I https://storeadmin.remiges.tech/health
curl -i https://baptest.remiges.tech/bap/receiver/on_select
curl -i https://bpptest.remiges.tech/bpp/caller/publish
curl -i https://bapapp.remiges.tech/api/webhook
curl -i https://bppapp.remiges.tech/api/webhook
curl -I https://shop.remiges.tech
sudo journalctl -u caddy -f
```

A `404`, `400`, or `405` can still mean the route is reachable. The important part is that the request reaches ONIX through Caddy.

## Logs

Caddy:

```bash
sudo journalctl -u caddy -f
```

ONIX adapters:

```bash
cd ~/localretail/testnet/retail-devkit/install
docker compose -f docker-compose-adapter.yml logs -f onix-bap onix-bpp
```

Apps:

```bash
curl http://127.0.0.1:8083/health
curl -I https://bapapp.remiges.tech/health
curl http://127.0.0.1:8080/health
curl -I https://bppapp.remiges.tech/health
```
