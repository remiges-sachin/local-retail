# Adapter logging stack

This stack adds Grafana and Loki for the ONIX adapters in `local-retail`.

It only covers these adapter containers:
- `onix-bap`
- `onix-bpp`

It does not add app observability for:
- `bpp-application/bap-application`
- `bpp-application/bpp-application`

## Files

- `testnet/retail-devkit/install/docker-compose-logging.yml`
- `testnet/retail-devkit/install/loki/loki-config.yml`
- `testnet/retail-devkit/install/otel/bap.yaml`
- `testnet/retail-devkit/install/otel/bpp.yaml`
- `testnet/retail-devkit/install/grafana/provisioning/datasources/datasources.yml`
- `testnet/retail-devkit/install/grafana/provisioning/dashboards/dashboards.yml`
- `testnet/retail-devkit/install/grafana/provisioning/dashboards/json/logs/adapter-logs-dashboard.json`
- `testnet/retail-devkit/install/verify-logging.sh`

## What the collectors extract

Each collector parses:
1. the outer adapter stdout JSON line
2. the nested JSON string inside `body`

The collectors promote one stable Loki label:
- `service_name`

Service names now match the demo deployment containers:
- `onix-bap`
- `onix-bpp`

The collectors still parse the outer log JSON and nested `body` JSON, but the dashboard now filters transaction, action, module, level, and subscriber by matching the raw log line text.

Reason:
- this avoids pulling in adjacent debug lines that do not explicitly contain the transaction ID
- transaction filtering is now line-exact instead of resource-label based

## Ports

This logging stack uses:
- Grafana: `http://localhost:3300`
- Loki: `http://localhost:3100`
- BAP collector fluentd input: `localhost:24224`
- BPP collector fluentd input: `localhost:24225`
- BAP collector health: `http://localhost:13133`
- BPP collector health: `http://localhost:13134`

Grafana uses port `3300` so it does not collide with the local BAP frontend on `3000`.

## Start order

### 1. Start the logging stack

```bash
cd testnet/retail-devkit/install
docker compose -f docker-compose-logging.yml up -d
```

### 2. Recreate the adapters so the fluentd log driver is applied

```bash
cd testnet/retail-devkit/install
docker compose -f docker-compose-adapter.yml up -d --force-recreate onix-bap onix-bpp
```

The logging driver is part of container creation. Restarting without recreate is not enough.

## Grafana login

Default login:
- user: `admin`
- password: `admin`

You can override them when starting the logging stack:

```bash
GRAFANA_ADMIN_USER=admin \
GRAFANA_ADMIN_PASSWORD=change-me \
GRAFANA_ROOT_URL=http://localhost:3300 \
docker compose -f docker-compose-logging.yml up -d
```

## Failure behavior

The adapter compose uses Docker `fluentd` logging with:
- `fluentd-async: true`
- `mode: non-blocking`

This keeps adapter startup from depending on collector readiness.

Tradeoff:
- if the collector is down or unreachable, logs can be dropped
- the adapters should keep running

That is the intended behavior for this demo environment.

## Dashboard usage

Open Grafana and use `Adapter Logs Dashboard`.

Main filters:
- `Service`
- `Subscriber ID`
- `Action`
- `Module ID`
- `Level`
- `Transaction ID`
- `Message ID`
- `Search`

Behavior notes:
- `Service = All` now works by default
- `Transaction ID` now matches only lines whose raw log text actually contains that ID
- the panel title says `Adapter logs` because the logs originate on container stdout and are shipped to Loki through Docker fluentd logging

## Verification

Run:

```bash
./testnet/retail-devkit/install/verify-logging.sh
```

Default behavior:
- checks collector, Loki, and Grafana health
- generates one `select` request through the BAP caller
- captures the transaction ID used for that request
- checks that Loki can return BAP logs whose raw text contains that transaction ID
- checks that Loki can return BPP logs whose raw text contains that transaction ID
- checks that Loki can return BAP and BPP logs whose raw text contains the expected subscriber IDs

Manual verification mode:

```bash
GENERATE_TRAFFIC=0 \
TRANSACTION_ID=<existing-transaction-id> \
./testnet/retail-devkit/install/verify-logging.sh
```

## Notes

Older logs may still exist under the earlier service names:
- `beckn-one-bap`
- `beckn-one-bpp`

New logs after collector restart use:
- `onix-bap`
- `onix-bpp`
