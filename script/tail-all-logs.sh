#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ONIX_COMPOSE_DIR="${REPO_ROOT}/testnet/retail-devkit/install"
ONIX_COMPOSE_FILE="docker-compose-adapter.yml"
APP_COMPOSE_DIR="${REPO_ROOT}/bpp-application"
APP_COMPOSE_FILE="docker-compose.yml"
CADDY_ACCESS_LOG="${CADDY_ACCESS_LOG:-/var/log/caddy/access.log}"
CALLBACK_LOG="${CALLBACK_LOG:-/tmp/on_publish_callback.log}"
INCLUDE_CALLBACK_LOG="${INCLUDE_CALLBACK_LOG:-1}"

pids=()

cleanup() {
  local pid
  for pid in "${pids[@]:-}"; do
    kill "$pid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT INT TERM

start_prefixed_stream() {
  local prefix="$1"
  shift
  (
    stdbuf -oL -eL "$@" 2>&1 | sed -u "s/^/[${prefix}] /"
  ) &
  pids+=("$!")
}

start_caddy_logs() {
  if [[ ${EUID} -eq 0 ]]; then
    start_prefixed_stream caddy journalctl -u caddy -f -n 50 --no-pager
    return
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    start_prefixed_stream caddy sudo -n journalctl -u caddy -f -n 50 --no-pager
    return
  fi

  echo "[tail-all-logs] Skipping Caddy logs. Run with sudo or allow passwordless sudo for journalctl." >&2
}

start_onix_logs() {
  (
    cd "${ONIX_COMPOSE_DIR}"
    stdbuf -oL -eL docker compose -f "${ONIX_COMPOSE_FILE}" logs -f --no-color onix-bap onix-bpp 2>&1 \
      | sed -u \
          -e 's/^onix-bap[[:space:]]*|/[onix-bap] /' \
          -e 's/^onix-bpp[[:space:]]*|/[onix-bpp] /' \
          -e 's/^/[onix] /'
  ) &
  pids+=("$!")
}

start_app_logs() {
  (
    cd "${APP_COMPOSE_DIR}"
    stdbuf -oL -eL docker compose -f "${APP_COMPOSE_FILE}" logs -f --no-color bap bpp frontend 2>&1 \
      | sed -u \
          -e 's/^bap[[:space:]]*|/[bap] /' \
          -e 's/^bpp[[:space:]]*|/[bpp] /' \
          -e 's/^frontend[[:space:]]*|/[frontend] /' \
          -e 's/^/[app] /'
  ) &
  pids+=("$!")
}

start_caddy_access_log() {
  if [[ -f "${CADDY_ACCESS_LOG}" ]]; then
    if [[ ${EUID} -eq 0 ]]; then
      start_prefixed_stream caddy-access tail -F "${CADDY_ACCESS_LOG}"
      return
    fi

    if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
      start_prefixed_stream caddy-access sudo -n tail -F "${CADDY_ACCESS_LOG}"
      return
    fi

    echo "[tail-all-logs] Skipping Caddy access log. Run with sudo or allow passwordless sudo for ${CADDY_ACCESS_LOG}." >&2
    return
  fi

  echo "[tail-all-logs] Caddy access log not found at ${CADDY_ACCESS_LOG}. Skipping it." >&2
}

start_callback_log() {
  if [[ "${INCLUDE_CALLBACK_LOG}" != "1" ]]; then
    return
  fi

  if [[ -f "${CALLBACK_LOG}" ]]; then
    start_prefixed_stream callback tail -F "${CALLBACK_LOG}"
  else
    echo "[tail-all-logs] Callback log not found at ${CALLBACK_LOG}. Skipping it." >&2
  fi
}

echo "[tail-all-logs] Starting log streams"
echo "[tail-all-logs] Caddy journal + Caddy access + ONIX + app logs"
echo "[tail-all-logs] Caddy access log path: ${CADDY_ACCESS_LOG}"
if [[ "${INCLUDE_CALLBACK_LOG}" == "1" ]]; then
  echo "[tail-all-logs] Callback log path: ${CALLBACK_LOG}"
fi

echo
start_caddy_logs
start_caddy_access_log
start_onix_logs
start_app_logs
start_callback_log

wait
