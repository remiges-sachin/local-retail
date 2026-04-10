# Catalog publish scripts

These scripts help you test catalog publishing from the Lightsail server.

## What these scripts do

- start the retail devkit stack
- check local and public BPP reachability
- render a publish payload with current timestamps and future validity dates
- publish the catalog through the local BPP caller
- publish the catalog through the public BPP caller
- tail BPP logs

## Prerequisites

Make sure these are already done:

- Docker is installed and working
- the stack config uses `bpptest.remiges.tech`
- `bpptest.remiges.tech` points to the server
- HTTPS is working for `https://bpptest.remiges.tech`
- the BPP subscriber is registered in the registry with the same `keyId` and public keys as the ONIX config

## Files

- `script/start-devkit.sh`
- `script/check-devkit.sh`
- `script/render-publish-payload.sh`
- `script/publish-catalog-local.sh`
- `script/publish-catalog-public.sh`
- `script/render-select-payload.sh`
- `script/select-local.sh`
- `script/select-public.sh`
- `script/tail-bpp-logs.sh`
- `script/tail-all-logs.sh`
- `script/confirm-on-publish.sh`

## Run order

### 1. Start the stack

```bash
./script/start-devkit.sh
```

This starts the containers from `testnet/retail-devkit/install/docker-compose-adapter.yml`.

### 2. Check health and reachability

```bash
./script/check-devkit.sh
```

What to look for:

- `onix-bap` and `onix-bpp` are running
- local BAP app health returns JSON
- public BAP app health returns an HTTP code
- local BPP app health returns JSON
- public BPP app health returns an HTTP code
- local or public BAP and BPP caller base return an HTTP code

A `404` or `405` for the caller base is fine. It still shows the route is reachable.

### 3. Preview the publish payload

```bash
./script/render-publish-payload.sh
```

This prints the JSON that will be sent.

You can override values for one run:

```bash
BPP_ID=bpptest.remiges.tech \
BPP_URI=https://bpptest.remiges.tech/bpp/receiver \
CATALOG_ID=catalog-remiges-001 \
PROVIDER_ID=provider-remiges-retail \
PROVIDER_NAME='Remiges Retail' \
./script/render-publish-payload.sh
```

## Select from BAP to BPP

The correct flow for `select` is:

- send `select` to the BAP caller
- the BAP caller forwards it to the BPP
- the BPP sends `on_select` back to the BAP receiver

The scripts below do exactly that.

### Preview the select payload

```bash
./script/render-select-payload.sh
```

Defaults:

- local BAP receiver: `http://localhost:8081/bap/receiver`
- local BPP receiver: `http://localhost:8082/bpp/receiver`
- public BAP receiver: `https://baptest.remiges.tech/bap/receiver`
- public BPP receiver: `https://bpptest.remiges.tech/bpp/receiver`

You can override key values for one run:

```bash
RESOURCE_ID=item-flask-mh500-yellow \
OFFER_ID=offer-flask-mh500-yellow \
PROVIDER_ID=provider-venky-bazaar \
PROVIDER_NAME='Venky.Mahadevan@Bazaar' \
./script/render-select-payload.sh
```

### Option A: select through localhost first

```bash
./script/select-local.sh
```

Default target:

- `http://localhost:8081/bap/caller/select`

This is the best first test because it removes Caddy and public internet routing from the request path.

### Option B: select through the public domain

```bash
./script/select-public.sh
```

Default target:

- `https://baptest.remiges.tech/bap/caller/select`

## Override the select URL

```bash
SELECT_URL=http://localhost:8081/bap/caller/select ./script/select-local.sh
SELECT_URL=https://baptest.remiges.tech/bap/caller/select ./script/select-public.sh
```

## Publish options

### Option A: publish through localhost first

```bash
./script/publish-catalog-local.sh
```

Default target:

- `http://localhost:8082/bpp/caller/publish`

This is the best first test because it removes nginx and TLS from the request path.

### Option B: publish through the public domain

```bash
./script/publish-catalog-public.sh
```

Default target:

- `https://bpptest.remiges.tech/bpp/caller/publish`

## Override the publish URL

If you need a different target for one run:

```bash
PUBLISH_URL=http://localhost:8082/bpp/caller/publish ./script/publish-catalog-local.sh
PUBLISH_URL=https://bpptest.remiges.tech/bpp/caller/publish ./script/publish-catalog-public.sh
```

## Watch logs while testing

For BPP-only logs:

```bash
./script/tail-bpp-logs.sh
```

For everything in one terminal:

```bash
./script/tail-all-logs.sh
```

This tails:

- Caddy logs
- ONIX adapter logs
- `/tmp/on_publish_callback.log` if it exists

If Caddy logs do not appear, run it with `sudo`:

```bash
sudo ./script/tail-all-logs.sh
```

## Typical workflow

Open two terminals.

Terminal 1:

```bash
./script/tail-all-logs.sh
```

Terminal 2:

```bash
./script/start-devkit.sh
./script/check-devkit.sh
./script/select-local.sh
./script/select-public.sh
./script/publish-catalog-local.sh
./script/publish-catalog-public.sh
```

## Confirming `catalog/on_publish`

If you want to confirm that the catalog service is calling you back with `catalog/on_publish`, start a simple callback listener:

```bash
./script/confirm-on-publish.sh
```

Default listener settings:

- bind: `127.0.0.1:18080`
- path: `/catalog/push`
- log file: `/tmp/on_publish_callback.log`

Expected public callback URL:

- `https://baptest.remiges.tech/catalog/push`

This listener works locally on `127.0.0.1:18080`.

If you are using the simplified whole-domain Caddy setup, `baptest.remiges.tech` now proxies everything to the BAP adapter on `127.0.0.1:8081`. That means `https://baptest.remiges.tech/catalog/push` will not reach this temporary listener unless you add a separate hostname or a path exception in Caddy.

So use this script mainly for local confirmation, or expose it on a separate callback hostname.

When a callback arrives, the script:

- prints the request body
- appends the raw request to `/tmp/on_publish_callback.log`
- returns a JSON ACK

You can probe it locally with:

```bash
curl -i http://127.0.0.1:18080/catalog/push
```

## Troubleshooting

### Docker permission denied

Run:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Then try again.

### Public select or publish fails but local works

Usually one of these is wrong:

- nginx routing
- TLS certificate
- DNS for `bpptest.remiges.tech`
- server firewall

### Publish is accepted locally but rejected upstream

Usually one of these is wrong:

- registry entry does not exist
- `keyId` does not match registry
- public key in registry does not match local private key
- server clock is off

## Notes

The payload generated by `render-publish-payload.sh` uses:

- `bpptest.remiges.tech` as the default BPP subscriber ID
- `https://bpptest.remiges.tech/bpp/receiver` as the default BPP receiver URL
- current timestamps
- validity dates that extend one year from now
