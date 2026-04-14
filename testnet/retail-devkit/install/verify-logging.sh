#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"
LOGGING_COMPOSE_DIR="${SCRIPT_DIR}"
LOGGING_COMPOSE_FILE="docker-compose-logging.yml"

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3300}"
LOKI_URL="${LOKI_URL:-http://localhost:3100}"
BAP_COLLECTOR_HEALTH_URL="${BAP_COLLECTOR_HEALTH_URL:-http://localhost:13133}"
BPP_COLLECTOR_HEALTH_URL="${BPP_COLLECTOR_HEALTH_URL:-http://localhost:13134}"
SELECT_URL="${SELECT_URL:-http://localhost:8081/bap/caller/select}"
GENERATE_TRAFFIC="${GENERATE_TRAFFIC:-1}"
BAP_ID="${BAP_ID:-baptest1.remiges.tech}"
BPP_ID="${BPP_ID:-bpptest1.remiges.tech}"
QUERY_WINDOW_SECONDS="${QUERY_WINDOW_SECONDS:-600}"

PAYLOAD_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "${PAYLOAD_FILE}" "${RESPONSE_FILE}"' EXIT

step() {
  printf '\n[%s] %s\n' "$1" "$2"
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

wait_for_http() {
  local url="$1"
  local name="$2"
  local attempts="${3:-30}"
  local sleep_seconds="${4:-2}"

  for _ in $(seq 1 "$attempts"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$sleep_seconds"
  done

  fail "$name did not become ready at $url"
}

query_loki() {
  local selector="$1"
  local output_file="$2"
  local now start_ns end_ns

  now="$(date +%s)"
  start_ns="$(((now - QUERY_WINDOW_SECONDS) * 1000000000))"
  end_ns="$(((now + 60) * 1000000000))"

  curl -G -fsS "${LOKI_URL}/loki/api/v1/query_range" \
    --data-urlencode "query=${selector}" \
    --data-urlencode 'limit=200' \
    --data-urlencode 'direction=backward' \
    --data-urlencode "start=${start_ns}" \
    --data-urlencode "end=${end_ns}" \
    > "${output_file}"
}

require docker
require curl

step 1 "Checking logging containers"
cd "${LOGGING_COMPOSE_DIR}"
services_output="$(docker compose -f "${LOGGING_COMPOSE_FILE}" ps --services --status running || true)"
for service in otel-collector-bap otel-collector-bpp loki grafana; do
  printf '%s\n' "${services_output}" | grep -qx "${service}" || fail "service is not running: ${service}"
done
printf 'Logging services are running.\n'

step 2 "Checking health endpoints"
wait_for_http "${BAP_COLLECTOR_HEALTH_URL}" "BAP collector"
wait_for_http "${BPP_COLLECTOR_HEALTH_URL}" "BPP collector"
wait_for_http "${LOKI_URL}/ready" "Loki"
wait_for_http "${GRAFANA_URL}/api/health" "Grafana"
printf 'BAP collector: %s\n' "$(curl -fsS "${BAP_COLLECTOR_HEALTH_URL}")"
printf 'BPP collector: %s\n' "$(curl -fsS "${BPP_COLLECTOR_HEALTH_URL}")"
printf 'Grafana health: %s\n' "$(curl -fsS "${GRAFANA_URL}/api/health")"

step 3 "Checking Loki query readiness"
curl -fsS "${LOKI_URL}/loki/api/v1/labels" >/dev/null
printf 'Loki query API is reachable.\n'

if [[ "${GENERATE_TRAFFIC}" == "1" ]]; then
  TRANSACTION_ID="${TRANSACTION_ID:-$(cat /proc/sys/kernel/random/uuid)}"
  MESSAGE_ID="${MESSAGE_ID:-$(cat /proc/sys/kernel/random/uuid)}"

  step 4 "Generating adapter traffic through the BAP caller"
  BAP_ID="${BAP_ID}" \
  BPP_ID="${BPP_ID}" \
  TRANSACTION_ID="${TRANSACTION_ID}" \
  MESSAGE_ID="${MESSAGE_ID}" \
  "${REPO_ROOT}/script/render-select-payload.sh" > "${PAYLOAD_FILE}"

  http_code="$({ curl -sS -o "${RESPONSE_FILE}" -w '%{http_code}' \
    -X POST "${SELECT_URL}" \
    -H 'Content-Type: application/json' \
    --data-binary @"${PAYLOAD_FILE}"; } || true)"

  printf 'Select URL: %s\n' "${SELECT_URL}"
  printf 'Transaction ID: %s\n' "${TRANSACTION_ID}"
  printf 'Message ID: %s\n' "${MESSAGE_ID}"
  printf 'HTTP status: %s\n' "${http_code}"
  printf 'Response body: %s\n' "$(cat "${RESPONSE_FILE}")"

  [[ "${http_code}" =~ ^2 ]] || fail "select request failed with HTTP ${http_code}"
else
  TRANSACTION_ID="${TRANSACTION_ID:-}"
  [[ -n "${TRANSACTION_ID}" ]] || fail 'set TRANSACTION_ID when GENERATE_TRAFFIC=0'
  step 4 "Using the provided transaction ID"
  printf 'Transaction ID: %s\n' "${TRANSACTION_ID}"
fi

step 5 "Checking BAP logs for the transaction"
bap_query_file="$(mktemp)"
trap 'rm -f "${PAYLOAD_FILE}" "${RESPONSE_FILE}" "${bap_query_file}" "${bpp_query_file:-}" "${subscriber_bap_query_file:-}" "${subscriber_bpp_query_file:-}"' EXIT
for _ in $(seq 1 20); do
  query_loki "{service_name=\"onix-bap\"} |= \"${TRANSACTION_ID}\"" "${bap_query_file}"
  if grep -q '"values":\[\[' "${bap_query_file}"; then
    break
  fi
  sleep 2
done
grep -q '"values":\[\[' "${bap_query_file}" || fail 'did not find BAP logs for the transaction'
printf 'Found BAP logs for transaction %s.\n' "${TRANSACTION_ID}"

step 6 "Checking BPP logs for the transaction"
bpp_query_file="$(mktemp)"
for _ in $(seq 1 20); do
  query_loki "{service_name=\"onix-bpp\"} |= \"${TRANSACTION_ID}\"" "${bpp_query_file}"
  if grep -q '"values":\[\[' "${bpp_query_file}"; then
    break
  fi
  sleep 2
done
grep -q '"values":\[\[' "${bpp_query_file}" || fail 'did not find BPP logs for the transaction'
printf 'Found BPP logs for transaction %s.\n' "${TRANSACTION_ID}"

step 7 "Checking subscriber filters"
subscriber_bap_query_file="$(mktemp)"
subscriber_bpp_query_file="$(mktemp)"
query_loki "{service_name=\"onix-bap\"} |= \"${BAP_ID}\"" "${subscriber_bap_query_file}"
query_loki "{service_name=\"onix-bpp\"} |= \"${BPP_ID}\"" "${subscriber_bpp_query_file}"
grep -q '"values":\[\[' "${subscriber_bap_query_file}" || fail "did not find logs for subscriber_id=${BAP_ID}"
grep -q '"values":\[\[' "${subscriber_bpp_query_file}" || fail "did not find logs for subscriber_id=${BPP_ID}"
printf 'Found logs for subscriber IDs %s and %s.\n' "${BAP_ID}" "${BPP_ID}"

step 8 "Done"
printf 'Grafana: %s\n' "${GRAFANA_URL}"
printf 'Dashboard: Adapter Logs Dashboard\n'
printf 'Transaction ID: %s\n' "${TRANSACTION_ID}"
printf 'BAP subscriber_id: %s\n' "${BAP_ID}"
printf 'BPP subscriber_id: %s\n' "${BPP_ID}"
printf 'Suggested filters: service=onix-bap or onix-bpp, transaction_id=%s\n' "${TRANSACTION_ID}"
