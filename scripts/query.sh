#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# query.sh — Commandes de consultation du ledger (lecture seule)
# Usage : ./scripts/query.sh <COMMANDE> [ARGS...]
#
# Commandes disponibles :
#   get        <idLot>
#   history    <idLot>
#   bytype     <typeProduit>
#   byowner    <proprietaire>
# ─────────────────────────────────────────────────────────────────────────────

set -e

export PATH="${HOME}/fabric-samples/bin:$PATH"

CHANNEL_NAME="cacao-cafe-channel"
CC_NAME="trace-cacao"
ORGANIZATIONS_DIR="$(dirname "$0")/../organizations"

# ── Contexte peer Org1 ────────────────────────────────────────────────────────
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED="true"
export CORE_PEER_TLS_ROOTCERT_FILE="$ORGANIZATIONS_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="$ORGANIZATIONS_DIR/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

# ── Fonction de requête commune ───────────────────────────────────────────────
query() {
  local PAYLOAD="$1"
  echo ""
  echo "🔍 Requête : $PAYLOAD"
  echo "   → Canal : $CHANNEL_NAME  |  Contrat : $CC_NAME"
  echo ""
  RESULT=$(peer chaincode query \
    --channelID "$CHANNEL_NAME" \
    --name "$CC_NAME" \
    -c "$PAYLOAD")

  # Formater le JSON si jq est disponible
  if command -v jq &> /dev/null; then
    echo "$RESULT" | jq .
  else
    echo "$RESULT"
  fi
  echo ""
}

COMMAND=${1:-"help"}

case "$COMMAND" in
  get)
    # Obtenir l'état actuel d'un lot
    ID_LOT="${2:?'❌ idLot requis'}"
    query "{\"function\":\"ObtenirLot\",\"Args\":[\"$ID_LOT\"]}"
    ;;

  history)
    # Consulter l'historique complet d'un lot sur le ledger
    ID_LOT="${2:?'❌ idLot requis'}"
    query "{\"function\":\"HistoriqueLot\",\"Args\":[\"$ID_LOT\"]}"
    ;;

  bytype)
    # Tous les lots d'un type de produit donné (requête CouchDB)
    TYPE="${2:?'❌ typeProduit requis (cacao|café)'}"
    query "{\"function\":\"ObtenirLotsParType\",\"Args\":[\"$TYPE\"]}"
    ;;

  byowner)
    # Tous les lots d'un propriétaire donné (requête CouchDB)
    OWNER="${2:?'❌ proprietaire requis'}"
    query "{\"function\":\"ObtenirLotsParProprietaire\",\"Args\":[\"$OWNER\"]}"
    ;;

  help|*)
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   🌱 ChainCacao — query.sh                              ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  ./query.sh get     <idLot>                            ║"
    echo "║  ./query.sh history <idLot>                            ║"
    echo "║  ./query.sh bytype  <cacao|café>                       ║"
    echo "║  ./query.sh byowner <proprietaire>                     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    ;;
esac
