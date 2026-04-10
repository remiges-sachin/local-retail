#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_DIR="${REPO_ROOT}/testnet/retail-devkit/install"
COMPOSE_FILE="docker-compose-adapter.yml"
LOCAL_BAPAPP_HEALTH="${LOCAL_BAPAPP_HEALTH:-http://localhost:8083/health}"
PUBLIC_BAPAPP_HEALTH="${PUBLIC_BAPAPP_HEALTH:-https://bapapp.remiges.tech/health}"
LOCAL_BPPAPP_HEALTH="${LOCAL_BPPAPP_HEALTH:-http://localhost:8080/health}"
PUBLIC_BPPAPP_HEALTH="${PUBLIC_BPPAPP_HEALTH:-https://bppapp.remiges.tech/health}"
LOCAL_BAP_CALLER_BASE="${LOCAL_BAP_CALLER_BASE:-http://localhost:8081/bap/caller}"
PUBLIC_BAP_CALLER_BASE="${PUBLIC_BAP_CALLER_BASE:-https://baptest.remiges.tech/bap/caller}"
LOCAL_BPP_CALLER_BASE="${LOCAL_BPP_CALLER_BASE:-http://localhost:8082/bpp/caller}"
PUBLIC_BPP_CALLER_BASE="${PUBLIC_BPP_CALLER_BASE:-https://bpptest.remiges.tech/bpp/caller}"

status_code() {
  local url="$1"
  curl -k -sS -o /dev/null -w '%{http_code}' "$url" || true
}

echo '== Docker services =='
cd "${COMPOSE_DIR}"
docker compose -f "${COMPOSE_FILE}" ps

echo
echo '== BAP app health =='
echo "Local BAP app health: ${LOCAL_BAPAPP_HEALTH}"
curl -sS "${LOCAL_BAPAPP_HEALTH}" || true

echo
echo "Public BAP app health: ${PUBLIC_BAPAPP_HEALTH} -> HTTP $(status_code "${PUBLIC_BAPAPP_HEALTH}")"

echo
echo '== BPP app health =='
echo "Local BPP app health: ${LOCAL_BPPAPP_HEALTH}"
curl -sS "${LOCAL_BPPAPP_HEALTH}" || true

echo
echo "Public BPP app health: ${PUBLIC_BPPAPP_HEALTH} -> HTTP $(status_code "${PUBLIC_BPPAPP_HEALTH}")"

echo
echo '== Adapter reachability =='
echo "Local BAP caller base: ${LOCAL_BAP_CALLER_BASE} -> HTTP $(status_code "${LOCAL_BAP_CALLER_BASE}")"
echo "Public BAP caller base: ${PUBLIC_BAP_CALLER_BASE} -> HTTP $(status_code "${PUBLIC_BAP_CALLER_BASE}")"
echo "Local BPP caller base: ${LOCAL_BPP_CALLER_BASE} -> HTTP $(status_code "${LOCAL_BPP_CALLER_BASE}")"
echo "Public BPP caller base: ${PUBLIC_BPP_CALLER_BASE} -> HTTP $(status_code "${PUBLIC_BPP_CALLER_BASE}")"
echo 'A 404 or 405 still means the endpoint is reachable.'

echo
echo '== Clock =='
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl status | sed -n '1,8p'
else
  date -u
fi
