#!/bin/bash
# Internal script to be executed inside CLI container - ChainCacao

CHANNEL_NAME="chaincacaochannel"
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/tls/ca.crt
ORDERER_URL="orderer.chaincacao.com:7050"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function println() {
    echo -e "==> $1"
}

function error_exit() {
    echo -e "${RED}Error:${NC} $1"
    exit 1
}

# 1. Get Channel Block (Fetch or Create)
println "Checking if channel ${CHANNEL_NAME} already exists..."
# Try to fetch the block first
peer channel fetch config ${CHANNEL_NAME}.block -o $ORDERER_URL -c $CHANNEL_NAME --tls --cafile $ORDERER_CA > /dev/null 2>&1

if [ $? -eq 0 ]; then
    println "Channel already exists. Fetched ${CHANNEL_NAME}.block successfully."
else
    println "Channel does not exist. Creating channel ${CHANNEL_NAME}..."
    peer channel create -o $ORDERER_URL -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --tls --cafile $ORDERER_CA || error_exit "Failed to create channel"
fi

if [ ! -f "${CHANNEL_NAME}.block" ]; then
    error_exit "Channel block file ${CHANNEL_NAME}.block was not found!"
fi


# 2. Join Peers
# Function to join a specific peer
join_peer() {
    ORG=$1
    PORT=$2
    MSP=$3
    
    println "Joining Org ${ORG} (port ${PORT}) to channel..."
    
    export CORE_PEER_ADDRESS="peer0.${ORG}.chaincacao.com:${PORT}"
    export CORE_PEER_LOCALMSPID="${MSP}"
    export CORE_PEER_TLS_CERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/peers/peer0.${ORG}.chaincacao.com/tls/server.crt"
    export CORE_PEER_TLS_KEY_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/peers/peer0.${ORG}.chaincacao.com/tls/server.key"
    export CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/peers/peer0.${ORG}.chaincacao.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/users/Admin@${ORG}.chaincacao.com/msp"

    peer channel join -b ${CHANNEL_NAME}.block || error_exit "Failed to join Org ${ORG} to channel"
    println "Org ${ORG} joined successfully."
}

# Join all orgs
join_peer "producteurs" 7051 "OrgProducteursMSP"
join_peer "exportateurs" 8051 "OrgExportateursMSP"
join_peer "certif" 9051 "OrgCertifMSP"
join_peer "ministere" 10051 "OrgMinistereMSP"
join_peer "transformateurs" 11051 "OrgTransformateursMSP"

println "${GREEN}All peers joined the channel successfully!${NC}"
