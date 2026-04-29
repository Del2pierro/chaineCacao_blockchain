#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# query.sh — Commandes de consultation (V2 Refactorisée)
# ─────────────────────────────────────────────────────────────────────────────

set -e

CHANNEL_NAME="chaincacaochannel"
CC_NAME="chaincacao"
ORGANIZATIONS_DIR="$(dirname "$0")/../blockchain/organizations"

export CORE_PEER_LOCALMSPID="OrgProducteursMSP"
export CORE_PEER_TLS_ENABLED="true"
export CORE_PEER_TLS_ROOTCERT_FILE="$ORGANIZATIONS_DIR/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="$ORGANIZATIONS_DIR/peerOrganizations/producteurs.chaincacao.com/users/Admin@producteurs.chaincacao.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

query() {
  local PAYLOAD="$1"
  peer chaincode query \
    --channelID "$CHANNEL_NAME" \
    --name "$CC_NAME" \
    -c "$PAYLOAD"
}

COMMAND=${1:-"help"}

case "$COMMAND" in
  get-lot)
    query "{\"function\":\"GetLot\",\"Args\":[\"$2\"]}"
    ;;
  all-lots)
    query "{\"function\":\"GetAllLots\",\"Args\":[]}"
    ;;
  history)
    query "{\"function\":\"GetHistoryForAsset\",\"Args\":[\"$2\"]}"
    ;;
  by-status)
    query "{\"function\":\"QueryLotsByStatus\",\"Args\":[\"$2\"]}"
    ;;
  by-farmer)
    query "{\"function\":\"QueryLotsByFarmer\",\"Args\":[\"$2\"]}"
    ;;
  help|*)
    echo "Commandes : get-lot, all-lots, history, by-status, by-farmer"
    ;;
esac
