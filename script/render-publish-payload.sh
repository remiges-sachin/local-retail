#!/usr/bin/env bash
set -euo pipefail

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
START_DATE="$(date -u +%Y-%m-%dT00:00:00Z)"
END_DATE="$(date -u -d '+365 days' +%Y-%m-%dT23:59:59Z)"
MESSAGE_ID="${MESSAGE_ID:-$(cat /proc/sys/kernel/random/uuid)}"
TRANSACTION_ID="${TRANSACTION_ID:-$(cat /proc/sys/kernel/random/uuid)}"
NETWORK_ID="${NETWORK_ID:-ion.id/ion-winroom-0426}"
BPP_ID="${BPP_ID:-bpptest1.remiges.tech}"
BPP_URI="${BPP_URI:-https://bpptest.remiges.tech/bpp/receiver}"
CATALOG_ID="${CATALOG_ID:-catalog-remiges-retail-001}"
PROVIDER_ID="${PROVIDER_ID:-provider-remiges-retail}"
PROVIDER_NAME="${PROVIDER_NAME:-Remiges Retail}"
CATALOG_NAME="${CATALOG_NAME:-Remiges Retail Catalog}"
CATALOG_SHORT_DESC="${CATALOG_SHORT_DESC:-Retail catalog for testnet publishing}"

cat <<EOF
{
  "context": {
    "version": "2.0.0",
    "action": "catalog/publish",
    "timestamp": "${NOW}",
    "messageId": "${MESSAGE_ID}",
    "transactionId": "${TRANSACTION_ID}",
    "bppId": "${BPP_ID}",
    "bppUri": "${BPP_URI}",
    "ttl": "PT30S",
    "networkId": "${NETWORK_ID}"
  },
  "message": {
    "catalogs": [
      {
        "id": "${CATALOG_ID}",
        "bppId": "${BPP_ID}",
        "bppUri": "${BPP_URI}",
        "descriptor": {
          "name": "${CATALOG_NAME}",
          "shortDesc": "${CATALOG_SHORT_DESC}"
        },
        "provider": {
          "id": "${PROVIDER_ID}",
          "descriptor": {
            "name": "${PROVIDER_NAME}"
          }
        },
        "validity": {
          "startDate": "${START_DATE}",
          "endDate": "${END_DATE}"
        },
        "resources": [
          {
            "id": "item-flask-mh500-yellow",
            "descriptor": {
              "name": "Isothermal Iron Flask MH500 Khaki",
              "shortDesc": "Triple-walled vacuum insulated stainless steel flask, 5000 ml",
              "mediaFile": [
                {
                  "label": "Product Image",
                  "mimeType": "image/jpeg",
                  "uri": "https://tourism-bpp-infra2.becknprotocol.io/attachments/view/253.jpg"
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
                "weight": {
                  "unitCode": "G",
                  "unitQuantity": 350
                },
                "volume": {
                  "unitCode": "ML",
                  "unitQuantity": 500
                },
                "dimensions": {
                  "unit": "CM",
                  "length": 25,
                  "breadth": 7,
                  "height": 7
                },
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
                "netQuantity": {
                  "unitCode": "ML",
                  "unitQuantity": 500
                }
              }
            }
          }
        ],
        "offers": [
          {
            "id": "offer-flask-mh500-yellow",
            "descriptor": {
              "name": "Isothermal Stainless Steel Hiking Flask MH500 Yellow"
            },
            "resourceIds": [
              "item-flask-mh500-yellow"
            ],
            "provider": {
              "id": "${PROVIDER_ID}",
              "descriptor": {
                "name": "${PROVIDER_NAME}"
              }
            },
            "validity": {
              "startDate": "${START_DATE}",
              "endDate": "${END_DATE}"
            },
            "offerAttributes": {
              "@context": "https://raw.githubusercontent.com/beckn/local-retail/refs/heads/main/schema/RetailOffer/v2.1/context.jsonld",
              "@type": "RetailOffer",
              "policies": {
                "returns": {
                  "allowed": true,
                  "window": "P7D",
                  "method": "SELLER_PICKUP"
                },
                "cancellation": {
                  "allowed": true,
                  "window": "PT2H",
                  "cutoffEvent": "BEFORE_PACKING"
                },
                "replacement": {
                  "allowed": true,
                  "window": "P7D",
                  "method": "SELLER_PICKUP",
                  "subjectToAvailability": true
                }
              },
              "paymentConstraints": {
                "codAvailable": true
              },
              "serviceability": {
                "distanceConstraint": {
                  "maxDistance": 15,
                  "unit": "KM"
                },
                "timing": [
                  {
                    "daysOfWeek": [
                      "MON",
                      "TUE",
                      "WED",
                      "THU",
                      "FRI",
                      "SAT",
                      "SUN"
                    ],
                    "timeRange": {
                      "start": "09:00",
                      "end": "21:00"
                    }
                  }
                ]
              }
            }
          }
        ]
      }
    ]
  }
}
EOF
