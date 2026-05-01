#!/bin/bash
# ChainCacao - Chaincode Deployment Script (FIXED & PRODUCTION READY)

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd "$DIR/.." && pwd)"

export PATH="$ROOT_DIR/../bin:$PATH"
export FABRIC_CFG_PATH="$ROOT_DIR/network"

CC_NAME="chaincacao"
CC_VERSION="1.2"
CC_SEQUENCE="3"
CC_PATH="/opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode"
CC_LANG="node"
CHANNEL_NAME="chaincacaochannel"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

println() {
  echo -e "${BLUE}==>${NC} $1"
}

error_exit() {
  echo -e "${RED}Error:${NC} $1"
  exit 1
}

println "Packaging chaincode..."

docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz \
  --path ${CC_PATH} \
  --lang ${CC_LANG} \
  --label ${CC_NAME}_${CC_VERSION} \
  || error_exit "Packaging failed"

println "Installing on all orgs + approving..."

install_and_approve() {
    ORG=$1
    MSP=$2
    PORT=$3

    println "→ Installing on ${ORG}"

    docker exec -e CORE_PEER_ADDRESS=peer0.${ORG}.chaincacao.com:${PORT} \
                -e CORE_PEER_LOCALMSPID=${MSP} \
                -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/users/Admin@${ORG}.chaincacao.com/msp \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/peers/peer0.${ORG}.chaincacao.com/tls/ca.crt \
                cli peer lifecycle chaincode install ${CC_NAME}.tar.gz || println "Le chaincode est déjà installé sur ${ORG}, passage à l'approbation..."

    PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep ${CC_NAME}_${CC_VERSION} | awk '{print $3}' | cut -d',' -f1)

    println "→ Approving ${ORG}"

    docker exec -e CORE_PEER_ADDRESS=peer0.${ORG}.chaincacao.com:${PORT} \
                -e CORE_PEER_LOCALMSPID=${MSP} \
                -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/users/Admin@${ORG}.chaincacao.com/msp \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/peers/peer0.${ORG}.chaincacao.com/tls/ca.crt \
                cli peer lifecycle chaincode approveformyorg \
        -o orderer.chaincacao.com:7050 \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --package-id ${PACKAGE_ID} \
        --sequence ${CC_SEQUENCE} \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/tls/ca.crt || println "Le chaincode est déjà approuvé par ${ORG}, on continue..."

}

install_and_approve "producteurs" "OrgProducteursMSP" 7051
install_and_approve "exportateurs" "OrgExportateursMSP" 8051
install_and_approve "certif" "OrgCertifMSP" 9051
install_and_approve "ministere" "OrgMinistereMSP" 10051
install_and_approve "transformateurs" "OrgTransformateursMSP" 11051

println "Committing chaincode to channel..."

docker exec -e CORE_PEER_ADDRESS=peer0.producteurs.chaincacao.com:7051 \
            -e CORE_PEER_LOCALMSPID=OrgProducteursMSP \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/users/Admin@producteurs.chaincacao.com/msp \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt \
            cli peer lifecycle chaincode commit \
  -o orderer.chaincacao.com:7050 \
  --ordererTLSHostnameOverride orderer.chaincacao.com \
  --channelID ${CHANNEL_NAME} \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence ${CC_SEQUENCE} \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/tls/ca.crt \
  --collections-config /opt/gopath/src/github.com/hyperledger/fabric/peer/network/collections_config.json \
  --peerAddresses peer0.producteurs.chaincacao.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt \
  --peerAddresses peer0.exportateurs.chaincacao.com:8051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/exportateurs.chaincacao.com/peers/peer0.exportateurs.chaincacao.com/tls/ca.crt \
  --peerAddresses peer0.certif.chaincacao.com:9051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/certif.chaincacao.com/peers/peer0.certif.chaincacao.com/tls/ca.crt \
  --peerAddresses peer0.ministere.chaincacao.com:10051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/ministere.chaincacao.com/peers/peer0.ministere.chaincacao.com/tls/ca.crt \
  --peerAddresses peer0.transformateurs.chaincacao.com:11051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/transformateurs.chaincacao.com/peers/peer0.transformateurs.chaincacao.com/tls/ca.crt

println "${GREEN}Chaincode ${CC_NAME} deployed successfully 🚀${NC}"