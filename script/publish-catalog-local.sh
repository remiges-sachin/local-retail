#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PUBLISH_URL="${PUBLISH_URL:-http://localhost:8082/bpp/caller/publish}"
PAYLOAD_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "${PAYLOAD_FILE}" "${RESPONSE_FILE}"' EXIT

"${SCRIPT_DIR}/render-publish-payload.sh" > "${PAYLOAD_FILE}"

echo "Payload written to: ${PAYLOAD_FILE}"
echo "Publishing to: ${PUBLISH_URL}"

echo
HTTP_CODE="$({ curl -sS -o "${RESPONSE_FILE}" -w '%{http_code}' \
  -X POST "${PUBLISH_URL}" \
  -H 'Content-Type: application/json' \
  --data-binary @"${PAYLOAD_FILE}"; } || true)"

echo "HTTP ${HTTP_CODE}"
echo
cat "${RESPONSE_FILE}"
