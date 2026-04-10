#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SELECT_URL="${SELECT_URL:-http://localhost:8081/bap/caller/select}"
PAYLOAD_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "${PAYLOAD_FILE}" "${RESPONSE_FILE}"' EXIT

BAP_ID="${BAP_ID:-baptest.remiges.tech}" \
BAP_URI="${BAP_URI:-http://localhost:8081/bap/receiver}" \
BPP_ID="${BPP_ID:-bpptest.remiges.tech}" \
BPP_URI="${BPP_URI:-http://localhost:8082/bpp/receiver}" \
"${SCRIPT_DIR}/render-select-payload.sh" > "${PAYLOAD_FILE}"

echo "Payload written to: ${PAYLOAD_FILE}"
echo "Selecting via: ${SELECT_URL}"
echo
HTTP_CODE="$({ curl -sS -o "${RESPONSE_FILE}" -w '%{http_code}' \
  -X POST "${SELECT_URL}" \
  -H 'Content-Type: application/json' \
  --data-binary @"${PAYLOAD_FILE}"; } || true)"

echo "HTTP ${HTTP_CODE}"
echo
cat "${RESPONSE_FILE}"
