#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_DIR="${REPO_ROOT}/testnet/retail-devkit/install"
COMPOSE_FILE="docker-compose-adapter.yml"
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

start_docker_logs() {
  cd "${COMPOSE_DIR}"
  start_prefixed_stream docker docker compose -f "${COMPOSE_FILE}" logs -f --no-color onix-bap onix-bpp
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
echo "[tail-all-logs] Caddy + ONIX logs"
if [[ "${INCLUDE_CALLBACK_LOG}" == "1" ]]; then
  echo "[tail-all-logs] Callback log path: ${CALLBACK_LOG}"
fi

echo
start_caddy_logs
start_docker_logs
start_callback_log

wait
