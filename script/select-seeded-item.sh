#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SEED_FIRST="${SEED_FIRST:-1}"
SELECT_URL="${SELECT_URL:-https://baptest.remiges.tech/bap/caller/select}"

NETWORK_ID="${NETWORK_ID:-ion.id/ion-winroom-0426}"
BAP_ID="${BAP_ID:-baptest1.remiges.tech}"
BAP_URI="${BAP_URI:-https://baptest.remiges.tech/bap/receiver}"
BPP_ID="${BPP_ID:-bpptest1.remiges.tech}"
BPP_URI="${BPP_URI:-https://bpptest.remiges.tech/bpp/receiver}"

PROVIDER_ID="${PROVIDER_ID:-provider-venky-bazaar}"
PROVIDER_NAME="${PROVIDER_NAME:-Venky.Mahadevan@Bazaar}"
RESOURCE_ID="${RESOURCE_ID:-item-flask-mh500-yellow}"
OFFER_ID="${OFFER_ID:-offer-flask-mh500-yellow}"
OFFER_NAME="${OFFER_NAME:-Isothermal Stainless Steel Hiking Flask MH500 Yellow}"
QUANTITY="${QUANTITY:-2}"

PAYLOAD_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "${PAYLOAD_FILE}" "${RESPONSE_FILE}"' EXIT

if [[ "${SEED_FIRST}" == "1" ]]; then
  echo "==> Seeding inventory before select"
  APP_PUBLISH_URL="${APP_PUBLISH_URL:-http://localhost:8080/api/v1/catalog/publish}" \
  CALLER_PUBLISH_URL="${CALLER_PUBLISH_URL:-http://localhost:8082/bpp/caller/publish}" \
  PUBLISH_TO_NETWORK="${PUBLISH_TO_NETWORK:-1}" \
  NETWORK_ID="${NETWORK_ID}" \
  BPP_ID="${BPP_ID}" \
  BPP_URI="${BPP_URI}" \
  PROVIDER_ID="${PROVIDER_ID}" \
  PROVIDER_NAME="${PROVIDER_NAME}" \
  RESOURCE_ID="${RESOURCE_ID}" \
  RESOURCE_NAME="${OFFER_NAME}" \
  OFFER_ID="${OFFER_ID}" \
  "${SCRIPT_DIR}/seed-item-and-publish.sh"
fi

BAP_ID="${BAP_ID}" \
BAP_URI="${BAP_URI}" \
BPP_ID="${BPP_ID}" \
BPP_URI="${BPP_URI}" \
NETWORK_ID="${NETWORK_ID}" \
PROVIDER_ID="${PROVIDER_ID}" \
PROVIDER_NAME="${PROVIDER_NAME}" \
RESOURCE_ID="${RESOURCE_ID}" \
OFFER_ID="${OFFER_ID}" \
OFFER_NAME="${OFFER_NAME}" \
QUANTITY="${QUANTITY}" \
"${SCRIPT_DIR}/render-select-payload.sh" > "${PAYLOAD_FILE}"

echo
echo "==> Sending select"
echo "Select URL: ${SELECT_URL}"
echo "Payload file: ${PAYLOAD_FILE}"

HTTP_CODE="$({ curl -sS -o "${RESPONSE_FILE}" -w '%{http_code}' \
  -X POST "${SELECT_URL}" \
  -H 'Content-Type: application/json' \
  --data-binary @"${PAYLOAD_FILE}"; } || true)"

echo "HTTP ${HTTP_CODE}"
echo
cat "${RESPONSE_FILE}"
echo

echo "If inventory is seeded correctly, the BPP should stop logging:"
echo "  offer \"${OFFER_ID}\" not found in inventory"
echo
if [[ "${HTTP_CODE}" =~ ^2 ]]; then
  echo "The select request reached the BAP caller."
  echo "Now watch BPP and ONIX logs for the async on_select callback."
else
  echo "Select failed with HTTP ${HTTP_CODE}" >&2
  exit 1
fi
