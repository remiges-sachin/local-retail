#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_DIR="${REPO_ROOT}/testnet/retail-devkit/install"
COMPOSE_FILE="docker-compose-adapter.yml"

cd "${COMPOSE_DIR}"
docker compose -f "${COMPOSE_FILE}" logs -f onix-bpp
