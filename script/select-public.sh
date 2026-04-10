#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SELECT_URL="${SELECT_URL:-https://baptest.remiges.tech/bap/caller/select}"
PAYLOAD_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "${PAYLOAD_FILE}" "${RESPONSE_FILE}"' EXIT

BAP_ID="${BAP_ID:-baptest1.remiges.tech}" \
BAP_URI="${BAP_URI:-https://baptest.remiges.tech/bap/receiver}" \
BPP_ID="${BPP_ID:-bpptest1.remiges.tech}" \
BPP_URI="${BPP_URI:-https://bpptest.remiges.tech/bpp/receiver}" \
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
