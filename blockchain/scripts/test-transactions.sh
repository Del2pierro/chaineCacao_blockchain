#!/bin/bash
# ChainCacao - Transaction Test Script

# Get directory info
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd "$DIR/.." && pwd)"

CHANNEL_NAME="chaincacaochannel"
CC_NAME="chaincacao"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

println() {
  echo -e "${BLUE}==>${NC} $1"
}

# Test 1: Register an Actor (Role: MINISTERE required)
println "Test 1: Registering a new actor (Producer) by the Ministry..."
docker exec -e CORE_PEER_LOCALMSPID=OrgMinistereMSP \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/ministere.chaincacao.com/users/Admin@ministere.chaincacao.com/msp \
            -e CORE_PEER_ADDRESS=peer0.ministere.chaincacao.com:7051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/ministere.chaincacao.com/peers/peer0.ministere.chaincacao.com/tls/ca.crt \
            cli peer chaincode invoke -o orderer.chaincacao.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/tls/ca.crt -C ${CHANNEL_NAME} -n ${CC_NAME} \
            --peerAddresses peer0.producteurs.chaincacao.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt \
            --peerAddresses peer0.exportateurs.chaincacao.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/exportateurs.chaincacao.com/peers/peer0.exportateurs.chaincacao.com/tls/ca.crt \
            --peerAddresses peer0.ministere.chaincacao.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/ministere.chaincacao.com/peers/peer0.ministere.chaincacao.com/tls/ca.crt \
            -c '{"function":"RegisterActor","Args":["ACTOR_001","PRODUCTEUR","PUB_KEY_XYZ"]}'


# Test 2: Create a Lot (Role: PRODUCTEUR required)
println "Test 2: Creating a cocoa lot by the Cooperative..."
# Note: In a real scenario, you would use the registered actor's identity, here we use Admin for simplicity if AC allows it, 
# but the contract checks for the PRODUCTEUR role in the certificate attributes.
GPS_DATA='{"latitude":5.34,"longitude":-4.02}'
GPS_JSON=$(echo $GPS_DATA | sed 's/"/\\"/g')

docker exec -e CORE_PEER_LOCALMSPID=OrgProducteursMSP \
            -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/users/Admin@producteurs.chaincacao.com/msp \
            -e CORE_PEER_ADDRESS=peer0.producteurs.chaincacao.com:7051 \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt \
            cli peer chaincode invoke -o orderer.chaincacao.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/tls/ca.crt -C ${CHANNEL_NAME} -n ${CC_NAME} \
            --peerAddresses peer0.producteurs.chaincacao.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt \
            --peerAddresses peer0.exportateurs.chaincacao.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/exportateurs.chaincacao.com/peers/peer0.exportateurs.chaincacao.com/tls/ca.crt \
            --peerAddresses peer0.ministere.chaincacao.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/ministere.chaincacao.com/peers/peer0.ministere.chaincacao.com/tls/ca.crt \
            -c "{\"function\":\"CreateLot\",\"Args\":[\"LOT_2024_001\",\"FARMER_ABC\",\"$GPS_JSON\",\"500\",\"Forastero\",\"2024-05-01T10:00:00Z\",\"MEDIA_HASH_123\",\"COOP_XYZ\"]}"




println "${GREEN}Test transactions submitted successfully.${NC}"
