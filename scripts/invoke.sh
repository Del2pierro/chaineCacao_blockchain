#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# invoke.sh — Commandes d'invocation du contrat intelligent
# Usage : ./scripts/invoke.sh <COMMANDE> [ARGS...]
#
# Commandes disponibles :
#   create    <idLot> <typeProduit> <origine> <proprietaire>
#   update    <idLot> <statut>
#   transfer  <idLot> <nouveauProprietaire>
#   init
# ─────────────────────────────────────────────────────────────────────────────

set -e

export PATH="${HOME}/fabric-samples/bin:$PATH"

# ── Variables réseau ──────────────────────────────────────────────────────────
CHANNEL_NAME="cacao-cafe-channel"
CC_NAME="trace-cacao"
ORGANIZATIONS_DIR="$(dirname "$0")/../organizations"
ORDERER_CA="$ORGANIZATIONS_DIR/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# ── Contexte d'appel Org1 (Producteur par défaut) ────────────────────────────
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ENABLED="true"
export CORE_PEER_TLS_ROOTCERT_FILE="$ORGANIZATIONS_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="$ORGANIZATIONS_DIR/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

# ── Fonction d'invocation commune ────────────────────────────────────────────
invoke() {
  local PAYLOAD="$1"
  echo ""
  echo "📤 Invocation : $PAYLOAD"
  echo "   → Canal   : $CHANNEL_NAME"
  echo "   → Contrat : $CC_NAME"
  echo ""
  peer chaincode invoke \
    -o localhost:7050 \
    --channelID "$CHANNEL_NAME" \
    --name "$CC_NAME" \
    --tls --cafile "$ORDERER_CA" \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "$ORGANIZATIONS_DIR/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "$ORGANIZATIONS_DIR/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
    -c "$PAYLOAD"
  echo ""
  echo "✅ Transaction soumise avec succès"
}

# ── Routage de la commande ────────────────────────────────────────────────────
COMMAND=${1:-"help"}

case "$COMMAND" in
  init)
    # Initialise le ledger avec les données de démonstration
    invoke '{"function":"InitLedger","Args":[]}'
    ;;

  create)
    # Crée un nouveau lot
    # Usage : ./invoke.sh create LOT-2024-001 cacao "Côte d'Ivoire - Lôh-Djiboua" Producteur_Konan
    ID_LOT="${2:?'❌ Argument manquant : idLot'}"
    TYPE="${3:?'❌ Argument manquant : typeProduit (cacao|café)'}"
    ORIGINE="${4:?'❌ Argument manquant : origine'}"
    PROPRIETAIRE="${5:?'❌ Argument manquant : proprietaire'}"
    invoke "{\"function\":\"CréationLot\",\"Args\":[\"$ID_LOT\",\"$TYPE\",\"$ORIGINE\",\"$PROPRIETAIRE\"]}"
    ;;

  update)
    # Met à jour le statut d'un lot
    # Usage : ./invoke.sh update LOT-2024-001 en_transit
    ID_LOT="${2:?'❌ Argument manquant : idLot'}"
    STATUT="${3:?'❌ Argument manquant : statut (créé|en_transit|transformé|exporté)'}"
    invoke "{\"function\":\"MiseAJourStatut\",\"Args\":[\"$ID_LOT\",\"$STATUT\"]}"
    ;;

  transfer)
    # Transfère la propriété d'un lot
    # Usage : ./invoke.sh transfer LOT-2024-001 Exportateur_Dupont
    ID_LOT="${2:?'❌ Argument manquant : idLot'}"
    NOUVEAU_PROPRIO="${3:?'❌ Argument manquant : nouveauProprietaire'}"
    invoke "{\"function\":\"TransfertPropriété\",\"Args\":[\"$ID_LOT\",\"$NOUVEAU_PROPRIO\"]}"
    ;;

  help|*)
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   🌱 ChainCacao — invoke.sh                             ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  ./invoke.sh init                                       ║"
    echo "║  ./invoke.sh create <id> <type> <origine> <proprio>    ║"
    echo "║  ./invoke.sh update <id> <statut>                      ║"
    echo "║  ./invoke.sh transfer <id> <nouveau_proprio>           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Statuts valides : créé | en_transit | transformé | exporté"
    echo "Types valides   : cacao | café"
    echo ""
    ;;
esac
