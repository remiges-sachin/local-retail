#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose-adapter.yml"
BPP_SERVICE="onix-bpp"
BPP_PORT="8082"
SUBDOMAIN="${1:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not in PATH" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Error: docker compose plugin is not available" >&2
  exit 1
fi

if ! command -v lt >/dev/null 2>&1; then
  echo "Error: localtunnel (lt) is not installed or not in PATH" >&2
  exit 1
fi

echo "[1/4] Starting adapter stack..."
docker compose -f "$COMPOSE_FILE" up -d

echo "[2/4] Waiting for local BPP on http://localhost:${BPP_PORT} ..."
for i in $(seq 1 30); do
  if curl -fsS "http://localhost:${BPP_PORT}" >/dev/null 2>&1; then
    break
  fi

  if [ "$i" -eq 30 ]; then
    echo "Error: BPP did not become reachable on port ${BPP_PORT}" >&2
    echo "Check logs with: docker compose -f ${COMPOSE_FILE} logs ${BPP_SERVICE}" >&2
    exit 1
  fi

  sleep 2
done

echo "[3/4] Current container status:"
docker compose -f "$COMPOSE_FILE" ps

echo "[4/4] Starting localtunnel..."
echo
if [ -n "$SUBDOMAIN" ]; then
  echo "Requested subdomain: $SUBDOMAIN"
  echo "Public BPP base URL will be: https://${SUBDOMAIN}.loca.lt"
  echo "Example endpoint: https://${SUBDOMAIN}.loca.lt/bpp/receiver/search"
  echo
  exec lt --port "$BPP_PORT" --subdomain "$SUBDOMAIN"
else
  echo "Public BPP base URL will be shown below once localtunnel connects."
  echo "Append /bpp/receiver/search to test the BPP endpoint."
  echo
  exec lt --port "$BPP_PORT"
fi
