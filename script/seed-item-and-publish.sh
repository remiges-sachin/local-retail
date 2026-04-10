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

RESOURCE_ID="${RESOURCE_ID:-}"
RESOURCE_NAME="${RESOURCE_NAME:-}"
OFFER_ID="${OFFER_ID:-}"
PRICE="${PRICE:-1200}"
CURRENCY="${CURRENCY:-INR}"
SEED_ITEM_COUNT="${SEED_ITEM_COUNT:-10}"
SEED_PREFIX="${SEED_PREFIX:-seed-$(date -u +%Y%m%d%H%M%S)-$RANDOM}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

PROVIDER_PAYLOAD="${TMP_DIR}/provider-publish.json"
BECKN_PAYLOAD="${TMP_DIR}/beckn-publish.json"

export BPP_ID BPP_URI NETWORK_ID
export CATALOG_ID PROVIDER_ID PROVIDER_NAME
export RESOURCE_ID RESOURCE_NAME OFFER_ID PRICE CURRENCY SEED_ITEM_COUNT SEED_PREFIX

python3 - <<'PY' "${PROVIDER_PAYLOAD}" "${BECKN_PAYLOAD}"
import json, os, re, sys, uuid
from datetime import datetime, timedelta, timezone

provider_path = sys.argv[1]
beckn_path = sys.argv[2]

BPP_ID = os.environ["BPP_ID"]
BPP_URI = os.environ["BPP_URI"]
NETWORK_ID = os.environ["NETWORK_ID"]
CATALOG_ID = os.environ["CATALOG_ID"]
PROVIDER_ID = os.environ["PROVIDER_ID"]
PROVIDER_NAME = os.environ["PROVIDER_NAME"]
RESOURCE_ID = os.environ.get("RESOURCE_ID", "").strip()
RESOURCE_NAME = os.environ.get("RESOURCE_NAME", "").strip()
OFFER_ID = os.environ.get("OFFER_ID", "").strip()
PRICE = float(os.environ["PRICE"])
CURRENCY = os.environ["CURRENCY"]
SEED_ITEM_COUNT = max(1, int(os.environ.get("SEED_ITEM_COUNT", "10")))
SEED_PREFIX = os.environ.get("SEED_PREFIX", "").strip()

now = datetime.now(timezone.utc)
ts = now.replace(microsecond=0).isoformat().replace("+00:00", "Z")
start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat().replace("+00:00", "Z")
end = (now + timedelta(days=365)).replace(hour=23, minute=59, second=59, microsecond=0).isoformat().replace("+00:00", "Z")

if not SEED_PREFIX:
    SEED_PREFIX = f"seed-{now.strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6]}"

slug = re.sub(r"[^a-z0-9-]+", "-", SEED_PREFIX.lower()).strip("-") or f"seed-{uuid.uuid4().hex[:6]}"

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

JAVA_COFFEE_ITEMS = [
    {
        "id": "java-burma-arabica-whole-beans-999",
        "name": "Java Burma Arabica Whole Beans 250g",
        "short_desc": "Biji kopi arabica Java dengan rasa cocoa dan kacang panggang",
        "long_desc": "Medium roast whole beans from Java with a smooth body, mild acidity, and notes of cocoa and toasted nuts. Cocok untuk pour-over, French press, dan espresso.",
        "image": "https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=1200&q=80",
        "price": 999,
        "unit_quantity": 250,
        "unit_code": "G",
        "generic_name": "Whole Bean Coffee"
    },
    {
        "id": "java-kopi-susu-botol-02",
        "name": "Kopi Susu Java Botol 300ml",
        "short_desc": "Ready-to-drink coffee milk with gula aren style sweetness",
        "long_desc": "Minuman kopi susu siap minum dengan karakter bold dari Java coffee beans. Smooth, slightly sweet, dan cocok disajikan dingin untuk konsumsi harian.",
        "image": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80",
        "price": 179,
        "unit_quantity": 300,
        "unit_code": "ML",
        "generic_name": "Ready to Drink Coffee"
    },
    {
        "id": "java-espresso-roast-03",
        "name": "Java Espresso Roast 500g",
        "short_desc": "Dark roast espresso blend untuk crema tebal dan body kuat",
        "long_desc": "Bold espresso roast made with Java coffee beans. Rich crema, dark chocolate notes, and a lingering smoky finish. Ideal untuk mesin espresso dan moka pot.",
        "image": "https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=1200&q=80",
        "price": 599,
        "unit_quantity": 500,
        "unit_code": "G",
        "generic_name": "Espresso Roast Coffee"
    },
    {
        "id": "java-kopi-tubruk-premium-04",
        "name": "Kopi Tubruk Java Premium 200g",
        "short_desc": "Bubuk kopi tubruk tradisional dengan aroma earthy dan kuat",
        "long_desc": "Kopi bubuk gaya tubruk dengan karakter full-bodied khas Java. Rasa pahit seimbang, aroma roasted, dan cocok untuk penyajian kopi hitam tradisional.",
        "image": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80",
        "price": 229,
        "unit_quantity": 200,
        "unit_code": "G",
        "generic_name": "Ground Coffee"
    },
    {
        "id": "java-cold-brew-blend-05",
        "name": "Java Cold Brew Blend 500ml",
        "short_desc": "Cold brew siap minum dengan finish dark chocolate",
        "long_desc": "Small-batch cold brew made from Java beans. Clean, bold flavor with low acidity and a dark chocolate finish. Enak disajikan chilled atau dengan es batu.",
        "image": "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=1200&q=80",
        "price": 189,
        "unit_quantity": 500,
        "unit_code": "ML",
        "generic_name": "Cold Brew Coffee"
    },
    {
        "id": "java-latte-mix-sachet-06",
        "name": "Java Latte Mix Sachet Pack",
        "short_desc": "Instant latte mix, creamy texture, praktis untuk harian",
        "long_desc": "Convenient latte mix with Java coffee flavor, creamy mouthfeel, and balanced sweetness. Cocok untuk office pantry, travel, atau quick coffee break.",
        "image": "https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&w=1200&q=80",
        "price": 149,
        "unit_quantity": 10,
        "unit_code": "EA",
        "generic_name": "Instant Coffee Mix"
    },
    {
        "id": "java-manis-cappuccino-07",
        "name": "Java Manis Cappuccino 250ml",
        "short_desc": "Minuman cappuccino chilled dengan foam style yang lembut",
        "long_desc": "Sweet cappuccino beverage inspired by cafe-style drinks. Menggabungkan Java coffee taste, creamy notes, dan rasa manis yang ringan untuk konsumsi santai.",
        "image": "https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=1200&q=80",
        "price": 165,
        "unit_quantity": 250,
        "unit_code": "ML",
        "generic_name": "Cappuccino Beverage"
    },
    {
        "id": "java-filter-coffee-drip-bags-08",
        "name": "Java Filter Coffee Drip Bags 8pcs",
        "short_desc": "Single-serve drip bags for quick brew, cocok untuk travel",
        "long_desc": "Portable drip coffee bags filled with ground Java coffee. Bright aroma, smooth taste, and easy brewing without extra equipment. Praktis untuk rumah dan perjalanan.",
        "image": "https://images.unsplash.com/photo-1494314671902-399b18174975?auto=format&fit=crop&w=1200&q=80",
        "price": 279,
        "unit_quantity": 8,
        "unit_code": "EA",
        "generic_name": "Drip Coffee Bags"
    },
    {
        "id": "java-kopi-hitam-classic-09",
        "name": "Kopi Hitam Java Classic 150g",
        "short_desc": "Classic black coffee powder dengan profil bold dan clean",
        "long_desc": "Traditional black coffee powder made from roasted Java beans. Rasa tegas, aroma pekat, dan aftertaste clean. Cocok untuk kopi hitam panas tanpa gula.",
        "image": "https://images.unsplash.com/photo-1459755486867-b55449bb39ff?auto=format&fit=crop&w=1200&q=80",
        "price": 199,
        "unit_quantity": 150,
        "unit_code": "G",
        "generic_name": "Black Coffee Powder"
    },
    {
        "id": "java-mocha-ready-drink-10",
        "name": "Java Mocha Ready Drink 330ml",
        "short_desc": "Chocolate coffee drink dengan rasa mocha yang smooth",
        "long_desc": "Ready-to-drink mocha made with Java coffee and cocoa notes. Smooth texture, balanced sweetness, and a dessert-like finish. Best served cold.",
        "image": "https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=1200&q=80",
        "price": 185,
        "unit_quantity": 330,
        "unit_code": "ML",
        "generic_name": "Mocha Beverage"
    }
]

def ensure_java_id(value: str, prefix: str) -> str:
    cleaned = re.sub(r"[^a-z0-9-]+", "-", value.lower()).strip("-")
    if "java" not in cleaned:
        cleaned = f"java-{cleaned}" if cleaned else "java"
    return cleaned if cleaned.startswith(f"{prefix}-") else f"{prefix}-{cleaned}"

def build_entry(resource_id: str, resource_name: str, offer_id: str, price: float, index: int, *, short_desc: str, long_desc: str, image_uri: str, unit_quantity: int, unit_code: str, generic_name: str):
    normalized_resource_id = ensure_java_id(resource_id, "item")
    normalized_offer_id = ensure_java_id(offer_id, "offer")

    resource = {
        "id": normalized_resource_id,
        "descriptor": {
            "name": resource_name,
            "shortDesc": short_desc,
            "longDesc": long_desc,
            "mediaFile": [
                {
                    "uri": image_uri,
                    "mimeType": "image/jpeg",
                    "label": resource_name
                }
            ]
        },
        "resourceAttributes": {
            "@context": "https://raw.githubusercontent.com/beckn/local-retail/refs/heads/main/schema/RetailResource/v2.1/context.jsonld",
            "@type": "RetailResource",
            "identity": {
                "brand": "Java House",
                "originCountry": "ID"
            },
            "physical": {
                "weight": {"unitCode": unit_code, "unitQuantity": unit_quantity}
            },
            "packagedGoodsDeclaration": {
                "manufacturerOrPacker": {
                    "type": "MANUFACTURER",
                    "name": "Java House Coffee Co.",
                    "address": "Jakarta, Indonesia"
                },
                "commonOrGenericName": generic_name,
                "netQuantity": {"unitCode": unit_code, "unitQuantity": unit_quantity}
            }
        }
    }

    offer = {
        "id": normalized_offer_id,
        "descriptor": {
            "name": resource_name,
            "shortDesc": f"Offer for {resource_name}"
        },
        "resourceIds": [normalized_resource_id],
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
                "id": f"consideration-java-{index:02d}",
                "status": {"name": "ACTIVE"},
                "considerationAttributes": {
                    "@context": "https://schema.beckn.io/RetailConsideration/v2.1/context.jsonld",
                    "@type": "RetailConsideration",
                    "currency": CURRENCY,
                    "breakup": [
                        {
                            "title": resource_name,
                            "amount": price,
                            "type": "BASE_PRICE"
                        }
                    ],
                    "totalAmount": price,
                    "paymentMethods": ["PREPAID", "COD", "UPI"]
                }
            }
        ]
    }

    return resource, offer

resources = []
offers = []

if RESOURCE_ID and OFFER_ID and RESOURCE_NAME:
    resource, offer = build_entry(
        RESOURCE_ID,
        RESOURCE_NAME,
        OFFER_ID,
        PRICE,
        1,
        short_desc=f"{RESOURCE_NAME} with Java coffee profile",
        long_desc=f"Catalog seed item for local testing. Search prefix: {SEED_PREFIX}.",
        image_uri="https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=1200&q=80",
        unit_quantity=250,
        unit_code="G",
        generic_name="Coffee Product"
    )
    resources.append(resource)
    offers.append(offer)
else:
    for i, item in enumerate(JAVA_COFFEE_ITEMS[:SEED_ITEM_COUNT], start=1):
        resource, offer = build_entry(
            item["id"],
            item["name"],
            f"offer-{item['id']}",
            item["price"],
            i,
            short_desc=item["short_desc"],
            long_desc=item["long_desc"],
            image_uri=item["image"],
            unit_quantity=item["unit_quantity"],
            unit_code=item["unit_code"],
            generic_name=item["generic_name"]
        )
        resources.append(resource)
        offers.append(offer)

catalog = {
    "id": CATALOG_ID,
    "descriptor": {
        "name": "Remiges Retail Catalog",
        "shortDesc": f"Retail catalog for select/on_select testing. Search prefix: {SEED_PREFIX}"
    },
    "provider": {
        "id": PROVIDER_ID,
        "descriptor": {"name": PROVIDER_NAME},
        "availableAt": [provider_location]
    },
    "resources": resources,
    "offers": offers,
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
echo "Inventory now contains seeded items with search prefix: ${SEED_PREFIX}"
echo "Tip: search by prefix '${SEED_PREFIX}' to find this run's items."
echo
if [[ "${PUBLISH_TO_NETWORK}" == "1" ]]; then
  echo "The same catalog was also published through the BPP caller."
fi
