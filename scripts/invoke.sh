#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# invoke.sh — Commandes d'invocation du contrat intelligent (V2 Refactorisée)
# Usage : ./scripts/invoke.sh <COMMANDE> [ARGS...]
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Variables réseau ──────────────────────────────────────────────────────────
CHANNEL_NAME="chaincacaochannel"
CC_NAME="chaincacao"
ORGANIZATIONS_DIR="$(dirname "$0")/../blockchain/organizations"
ORDERER_CA="$ORGANIZATIONS_DIR/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/msp/tlscacerts/tlsca.chaincacao.com-cert.pem"

# Default to OrgProducteurs for creation
export CORE_PEER_LOCALMSPID="OrgProducteursMSP"
export CORE_PEER_TLS_ENABLED="true"
export CORE_PEER_TLS_ROOTCERT_FILE="$ORGANIZATIONS_DIR/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="$ORGANIZATIONS_DIR/peerOrganizations/producteurs.chaincacao.com/users/Admin@producteurs.chaincacao.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

invoke() {
  local PAYLOAD="$1"
  peer chaincode invoke \
    -o localhost:7050 \
    --channelID "$CHANNEL_NAME" \
    --name "$CC_NAME" \
    --tls --cafile "$ORDERER_CA" \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "$ORGANIZATIONS_DIR/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt" \
    -c "$PAYLOAD"
}

COMMAND=${1:-"help"}

case "$COMMAND" in
  init)
    invoke '{"function":"initLedger","Args":[]}'
    ;;

  create-lot)
    # Usage : ./invoke.sh create-lot <lotHash> <farmerId> <gpsStr> <poidsKg> <espece> <dateCollecte> <mediaHash> <coopId>
    invoke "{\"function\":\"CreateLot\",\"Args\":[\"$2\",\"$3\",$4,\"$5\",\"$6\",\"$7\",\"$8\",\"$9\"]}"
    ;;

  update-status)
    invoke "{\"function\":\"UpdateLotStatus\",\"Args\":[\"$2\",\"$3\"]}"
    ;;

  transfer)
    # Usage : ./invoke.sh transfer <transferHash> <lotHashesArrayStr> <expediteurId> <destinataireId> <preuveHash>
    invoke "{\"function\":\"CreateTransfer\",\"Args\":[\"$2\",$3,\"$4\",\"$5\",\"$6\"]}"
    ;;

  shipment)
    invoke "{\"function\":\"CreateShipment\",\"Args\":[\"$2\",$3,\"$4\",\"$5\",\"$6\",\"$7\",\"$8\"]}"
    ;;

  help|*)
    echo "Commandes : init, create-lot, update-status, transfer, shipment"
    ;;
esac
