#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

APP_PUBLISH_URL="${APP_PUBLISH_URL:-http://localhost:8080/api/v1/catalog/publish}"
CALLER_PUBLISH_URL="${CALLER_PUBLISH_URL:-http://localhost:8082/bpp/caller/publish}"
PUBLISH_TO_NETWORK="${PUBLISH_TO_NETWORK:-1}"

BPP_ID="${BPP_ID:-bpptest1.remiges.tech}"
BPP_URI="${BPP_URI:-https://bpptest.remiges.tech/bpp/receiver}"
NETWORK_ID="${NETWORK_ID:-ion.id/ion-winroom-0426}"

CATALOG_ID="${CATALOG_ID:-catalog-remiges-retail-001}"
PROVIDER_ID="${PROVIDER_ID:-provider-venky-bazaar}"
PROVIDER_NAME="${PROVIDER_NAME:-Venky.Mahadevan@Bazaar}"

RESOURCE_ID="${RESOURCE_ID:-item-flask-mh500-yellow}"
RESOURCE_NAME="${RESOURCE_NAME:-Isothermal Stainless Steel Hiking Flask MH500 Yellow}"
OFFER_ID="${OFFER_ID:-offer-flask-mh500-yellow}"
PRICE="${PRICE:-1200}"
CURRENCY="${CURRENCY:-INR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

PROVIDER_PAYLOAD="${TMP_DIR}/provider-publish.json"
BECKN_PAYLOAD="${TMP_DIR}/beckn-publish.json"

export BPP_ID BPP_URI NETWORK_ID
export CATALOG_ID PROVIDER_ID PROVIDER_NAME
export RESOURCE_ID RESOURCE_NAME OFFER_ID PRICE CURRENCY

python3 - <<'PY' "${PROVIDER_PAYLOAD}" "${BECKN_PAYLOAD}"
import json, os, sys, uuid
from datetime import datetime, timedelta, timezone

provider_path = sys.argv[1]
beckn_path = sys.argv[2]

BPP_ID = os.environ["BPP_ID"]
BPP_URI = os.environ["BPP_URI"]
NETWORK_ID = os.environ["NETWORK_ID"]
CATALOG_ID = os.environ["CATALOG_ID"]
PROVIDER_ID = os.environ["PROVIDER_ID"]
PROVIDER_NAME = os.environ["PROVIDER_NAME"]
RESOURCE_ID = os.environ["RESOURCE_ID"]
RESOURCE_NAME = os.environ["RESOURCE_NAME"]
OFFER_ID = os.environ["OFFER_ID"]
PRICE = float(os.environ["PRICE"])
CURRENCY = os.environ["CURRENCY"]

now = datetime.now(timezone.utc)
ts = now.replace(microsecond=0).isoformat().replace("+00:00", "Z")
start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat().replace("+00:00", "Z")
end = (now + timedelta(days=365)).replace(hour=23, minute=59, second=59, microsecond=0).isoformat().replace("+00:00", "Z")

provider_location = {
    "geo": {"type": "Point", "coordinates": [77.5946, 12.9716]},
    "address": {
        "streetAddress": "1 MG Road",
        "addressLocality": "Bengaluru",
        "addressRegion": "Karnataka",
        "postalCode": "560001",
        "addressCountry": "IN"
    }
}

catalog = {
    "id": CATALOG_ID,
    "descriptor": {
        "name": "Remiges Retail Catalog",
        "shortDesc": "Retail catalog for select/on_select testing"
    },
    "provider": {
        "id": PROVIDER_ID,
        "descriptor": {"name": PROVIDER_NAME},
        "availableAt": [provider_location]
    },
    "resources": [
        {
            "id": RESOURCE_ID,
            "descriptor": {
                "name": RESOURCE_NAME,
                "shortDesc": "Double-walled insulated stainless steel flask, 500ml",
                "longDesc": "Catalog seed item used for local select/on_select testing.",
                "mediaFile": [
                    {
                        "uri": "https://tourism-bpp-infra2.becknprotocol.io/attachments/view/253.jpg",
                        "mimeType": "image/jpeg",
                        "label": "Product image"
                    }
                ]
            },
            "resourceAttributes": {
                "@context": "https://raw.githubusercontent.com/beckn/local-retail/refs/heads/main/schema/RetailResource/v2.1/context.jsonld",
                "@type": "RetailResource",
                "identity": {
                    "brand": "InstaCuppa",
                    "originCountry": "IN"
                },
                "physical": {
                    "weight": {"unitCode": "G", "unitQuantity": 350},
                    "volume": {"unitCode": "ML", "unitQuantity": 500},
                    "appearance": {
                        "color": "Yellow",
                        "material": "Stainless Steel",
                        "finish": "Matte"
                    }
                },
                "packagedGoodsDeclaration": {
                    "manufacturerOrPacker": {
                        "type": "MANUFACTURER",
                        "name": "InstaCuppa India Pvt Ltd",
                        "address": "Bangalore, Karnataka, IN"
                    },
                    "commonOrGenericName": "Stainless Steel Vacuum Flask",
                    "netQuantity": {"unitCode": "ML", "unitQuantity": 500}
                }
            }
        }
    ],
    "offers": [
        {
            "id": OFFER_ID,
            "descriptor": {
                "name": RESOURCE_NAME,
                "shortDesc": f"Offer for {RESOURCE_NAME}"
            },
            "resourceIds": [RESOURCE_ID],
            "provider": {
                "id": PROVIDER_ID,
                "descriptor": {"name": PROVIDER_NAME},
                "availableAt": [provider_location]
            },
            "validity": {
                "startDate": start,
                "endDate": end
            },
            "offerAttributes": {
                "@context": "https://raw.githubusercontent.com/beckn/local-retail/refs/heads/main/schema/RetailOffer/v2.1/context.jsonld",
                "@type": "RetailOffer",
                "policies": {
                    "returns": {
                        "allowed": True,
                        "window": "P7D",
                        "method": "SELLER_PICKUP"
                    },
                    "cancellation": {
                        "allowed": True,
                        "window": "PT2H",
                        "cutoffEvent": "BEFORE_PACKING"
                    },
                    "replacement": {
                        "allowed": True,
                        "window": "P7D",
                        "method": "SELLER_PICKUP",
                        "subjectToAvailability": True
                    }
                },
                "paymentConstraints": {"codAvailable": True},
                "serviceability": {
                    "distanceConstraint": {"maxDistance": 15, "unit": "KM"},
                    "timing": [
                        {
                            "daysOfWeek": ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"],
                            "timeRange": {"start": "09:00", "end": "21:00"}
                        }
                    ]
                }
            },
            "considerations": [
                {
                    "id": "consideration-flask-001",
                    "status": {"name": "ACTIVE"},
                    "considerationAttributes": {
                        "@context": "https://schema.beckn.io/RetailConsideration/v2.1/context.jsonld",
                        "@type": "RetailConsideration",
                        "currency": CURRENCY,
                        "breakup": [
                            {
                                "title": RESOURCE_NAME,
                                "amount": PRICE,
                                "type": "BASE_PRICE"
                            }
                        ],
                        "totalAmount": PRICE,
                        "paymentMethods": ["PREPAID", "COD", "UPI"]
                    }
                }
            ]
        }
    ],
    "publishDirectives": {"catalogType": "regular"}
}

provider_payload = {"catalogs": [catalog]}

beckn_catalog = dict(catalog)
beckn_catalog["bppId"] = BPP_ID
beckn_catalog["bppUri"] = BPP_URI

beckn_payload = {
    "context": {
        "version": "2.0.0",
        "action": "catalog/publish",
        "timestamp": ts,
        "messageId": str(uuid.uuid4()),
        "transactionId": str(uuid.uuid4()),
        "bppId": BPP_ID,
        "bppUri": BPP_URI,
        "ttl": "PT30S",
        "networkId": NETWORK_ID
    },
    "message": {"catalogs": [beckn_catalog]}
}

with open(provider_path, "w", encoding="utf-8") as f:
    json.dump(provider_payload, f, indent=2)

with open(beckn_path, "w", encoding="utf-8") as f:
    json.dump(beckn_payload, f, indent=2)
PY

post_json() {
  local url="$1"
  local payload="$2"
  local label="$3"
  local response_file="${TMP_DIR}/response.json"

  echo
  echo "==> ${label}"
  echo "URL: ${url}"
  echo "Payload: ${payload}"

  local http_code
  http_code="$({ curl -sS -o "${response_file}" -w '%{http_code}' \
    -X POST "${url}" \
    -H 'Content-Type: application/json' \
    --data-binary @"${payload}"; } || true)"

  echo "HTTP ${http_code}"
  echo
  cat "${response_file}"
  echo

  if [[ ! "${http_code}" =~ ^2 ]]; then
    echo "${label} failed with HTTP ${http_code}" >&2
    return 1
  fi
}

echo "Provider payload written to: ${PROVIDER_PAYLOAD}"
echo "Beckn payload written to:    ${BECKN_PAYLOAD}"

post_json "${APP_PUBLISH_URL}" "${PROVIDER_PAYLOAD}" "Seed inventory in BPP app"

if [[ "${PUBLISH_TO_NETWORK}" == "1" ]]; then
  post_json "${CALLER_PUBLISH_URL}" "${BECKN_PAYLOAD}" "Publish catalog through ONIX BPP caller"
else
  echo
  echo "Skipping network publish because PUBLISH_TO_NETWORK=${PUBLISH_TO_NETWORK}"
fi

echo
echo "Done."
echo "Inventory now contains:"
echo "  resource: ${RESOURCE_ID}"
echo "  offer:    ${OFFER_ID}"
echo
if [[ "${PUBLISH_TO_NETWORK}" == "1" ]]; then
  echo "The same item was also published through the BPP caller."
fi
