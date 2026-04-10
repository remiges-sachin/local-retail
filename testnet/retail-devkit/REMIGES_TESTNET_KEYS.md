# Remiges testnet public values and env variable map

This file is now safe to commit.
It does not contain private keys.

Actual private keys must be stored locally in:

- `testnet/retail-devkit/config/onix-secrets.env`

Start from this example file:

- `testnet/retail-devkit/config/onix-secrets.env.example`

## 1. Registry upload values

Upload only public values to the registry.
Keep the `subscriber_id`, `keyId`, and public keys aligned with your local env file.

### BAP registry entry

- subscriber_id: from `BAP_NETWORK_PARTICIPANT`
- subscriber_url / callback URL: `https://baptest.remiges.tech/bap/receiver`
- keyId: from `BAP_KEY_ID`
- signingPublicKey: from `BAP_SIGNING_PUBLIC_KEY`
- encrPublicKey: from `BAP_ENCR_PUBLIC_KEY`

### BPP registry entry

- subscriber_id: from `BPP_NETWORK_PARTICIPANT`
- subscriber_url / callback URL: `https://bpptest.remiges.tech/bpp/receiver`
- keyId: from `BPP_KEY_ID`
- signingPublicKey: from `BPP_SIGNING_PUBLIC_KEY`
- encrPublicKey: from `BPP_ENCR_PUBLIC_KEY`

## 2. ONIX config env variables

The ONIX YAML files now read these values from environment variables.

### BAP

- `BAP_NETWORK_PARTICIPANT`
- `BAP_KEY_ID`
- `BAP_SIGNING_PRIVATE_KEY`
- `BAP_SIGNING_PUBLIC_KEY`
- `BAP_ENCR_PRIVATE_KEY`
- `BAP_ENCR_PUBLIC_KEY`

### BPP

- `BPP_NETWORK_PARTICIPANT`
- `BPP_KEY_ID`
- `BPP_SIGNING_PRIVATE_KEY`
- `BPP_SIGNING_PUBLIC_KEY`
- `BPP_ENCR_PRIVATE_KEY`
- `BPP_ENCR_PUBLIC_KEY`

## 3. Files updated for env-based secret handling

- `testnet/retail-devkit/config/local-simple-bap.yaml`
- `testnet/retail-devkit/config/local-simple-bpp.yaml`
- `testnet/retail-devkit/install/docker-compose-adapter.yml`
- `testnet/retail-devkit/config/onix-secrets.env.example`
- `.gitignore`

## 4. Local setup

Copy the example file and fill in your private keys locally:

```bash
cp testnet/retail-devkit/config/onix-secrets.env.example testnet/retail-devkit/config/onix-secrets.env
```

Then start or restart the stack:

```bash
cd testnet/retail-devkit/install
docker compose -f docker-compose-adapter.yml down
docker compose -f docker-compose-adapter.yml up -d
```

## 5. Important note

If any private keys from earlier versions of this repo were pushed to a remote, rotate them before using this setup in a shared environment.
