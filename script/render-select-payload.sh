#!/usr/bin/env bash
set -euo pipefail

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
MESSAGE_ID="${MESSAGE_ID:-$(cat /proc/sys/kernel/random/uuid)}"
TRANSACTION_ID="${TRANSACTION_ID:-$(cat /proc/sys/kernel/random/uuid)}"
NETWORK_ID="${NETWORK_ID:-beckn.one/testnet-retail}"
BAP_ID="${BAP_ID:-baptest1.remiges.tech}"
BAP_URI="${BAP_URI:-https://baptest.remiges.tech/bap/receiver}"
BPP_ID="${BPP_ID:-bpptest1.remiges.tech}"
BPP_URI="${BPP_URI:-https://bpptest.remiges.tech/bpp/receiver}"
PROVIDER_ID="${PROVIDER_ID:-provider-venky-bazaar}"
PROVIDER_NAME="${PROVIDER_NAME:-Venky.Mahadevan@Bazaar}"
BUYER_ID="${BUYER_ID:-buyer-motiur-rehman}"
BUYER_NAME="${BUYER_NAME:-Motiur Rehman}"
BUYER_EMAIL="${BUYER_EMAIL:-nc.rehman@gmail.com}"
BUYER_PHONE="${BUYER_PHONE:-+919191223433}"
RESOURCE_ID="${RESOURCE_ID:-item-flask-mh500-yellow}"
OFFER_ID="${OFFER_ID:-offer-flask-mh500-yellow}"
OFFER_NAME="${OFFER_NAME:-Isothermal Stainless Steel Hiking Flask MH500 Yellow}"
LINE_ID="${LINE_ID:-LINE-001}"
QUANTITY="${QUANTITY:-2}"
DELIVERY_NAME="${DELIVERY_NAME:-Motiur Rehman}"
DELIVERY_PHONE="${DELIVERY_PHONE:-+919246394908}"
STREET_ADDRESS="${STREET_ADDRESS:-123, Terminal 1, Kempegowda Intl Airport Rd, A - Block}"
LOCALITY="${LOCALITY:-Gangamuthanahalli}"
REGION="${REGION:-Karnataka}"
POSTAL_CODE="${POSTAL_CODE:-560300}"
COUNTRY="${COUNTRY:-IND}"

cat <<EOF
{
  "context": {
    "version": "2.0.0",
    "action": "select",
    "timestamp": "${NOW}",
    "messageId": "${MESSAGE_ID}",
    "transactionId": "${TRANSACTION_ID}",
    "bapId": "${BAP_ID}",
    "bapUri": "${BAP_URI}",
    "bppId": "${BPP_ID}",
    "bppUri": "${BPP_URI}",
    "ttl": "PT30S",
    "networkId": "${NETWORK_ID}"
  },
  "message": {
    "contract": {
      "status": {
        "code": "DRAFT"
      },
      "participants": [
        {
          "id": "${PROVIDER_ID}",
          "descriptor": {
            "name": "${PROVIDER_NAME}"
          },
          "participantAttributes": {
            "@context": "https://raw.githubusercontent.com/beckn/schemas/main/schema/Provider/v2.1/context.jsonld",
            "@type": "Provider",
            "id": "${PROVIDER_ID}",
            "descriptor": {
              "name": "${PROVIDER_NAME}",
              "shortDesc": "Multi-category retail store specializing in electronics and home goods"
            }
          }
        },
        {
          "id": "${BUYER_ID}",
          "descriptor": {
            "name": "${BUYER_NAME}"
          },
          "participantAttributes": {
            "@context": "https://raw.githubusercontent.com/beckn/schemas/main/schema/Consumer/v2.0/context.jsonld",
            "@type": "Consumer",
            "role": "buyer",
            "person": {
              "id": "abc",
              "name": "${BUYER_NAME}",
              "email": "${BUYER_EMAIL}",
              "telephone": "${BUYER_PHONE}"
            }
          }
        }
      ],
      "commitments": [
        {
          "id": "commitment-flask-001",
          "status": {
            "descriptor": {
              "code": "DRAFT"
            }
          },
          "resources": [
            {
              "id": "${RESOURCE_ID}"
            }
          ],
          "offer": {
            "id": "${OFFER_ID}",
            "resourceIds": [
              "${RESOURCE_ID}"
            ],
            "descriptor": {
              "name": "${OFFER_NAME}"
            },
            "provider": {
              "id": "${PROVIDER_ID}",
              "descriptor": {
                "name": "${PROVIDER_NAME}"
              }
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
                }
              }
            }
          },
          "commitmentAttributes": {
            "@context": "https://raw.githubusercontent.com/beckn/local-retail/refs/heads/main/schema/RetailCommitment/v2.1/context.jsonld",
            "@type": "RetailCommitment",
            "lineId": "${LINE_ID}",
            "resourceId": "${RESOURCE_ID}",
            "quantity": {
              "unitCode": "EA",
              "unitQuantity": ${QUANTITY}
            }
          }
        }
      ],
      "performance": [
        {
          "id": "f1",
          "status": {
            "code": "PENDING"
          },
          "commitmentIds": [
            "commitment-flask-001"
          ],
          "performanceAttributes": {
            "@context": "https://raw.githubusercontent.com/beckn/local-retail/refs/heads/main/schema/RetailPerformance/v2.1/context.jsonld",
            "@type": "rcpa:RetailPerformance",
            "supportedPerformanceModes": [
              "DELIVERY"
            ],
            "deliveryDetails": {
              "address": {
                "streetAddress": "${STREET_ADDRESS}",
                "addressLocality": "${LOCALITY}",
                "addressRegion": "${REGION}",
                "postalCode": "${POSTAL_CODE}",
                "addressCountry": "${COUNTRY}"
              },
              "contact": {
                "name": "${DELIVERY_NAME}",
                "phone": "${DELIVERY_PHONE}"
              }
            },
            "operatingHours": [
              {
                "daysOfWeek": [1, 2, 3, 4, 5, 6],
                "timeRange": {
                  "start": "09:00",
                  "end": "21:00"
                }
              }
            ],
            "installationScheduling": {
              "available": false
            }
          }
        }
      ]
    }
  }
}
EOF
