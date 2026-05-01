#!/bin/bash
# Internal script to be executed inside CLI container - ChainCacao
set -x

CHANNEL_NAME="chaincacaochannel"
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/chaincacao.com/orderers/orderer.chaincacao.com/tls/ca.crt
ORDERER_URL="orderer.chaincacao.com:7050"

# Colors
BLUE='\033[0;34m'
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

# 1. Wait for Orderer
println "Waiting for Orderer to be ready..."
TIMEOUT=30
COUNTER=0
until (echo > /dev/tcp/orderer.chaincacao.com/7050) >/dev/null 2>&1 || [ $COUNTER -eq $TIMEOUT ]; do
    sleep 1
    COUNTER=$((COUNTER+1))
done
if [ $COUNTER -eq $TIMEOUT ]; then error_exit "Orderer timeout"; fi


# 2. Get Channel Block
println "Fetching genesis block..."
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_ADDRESS=peer0.producteurs.chaincacao.com:7051
export CORE_PEER_LOCALMSPID=OrgProducteursMSP
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/users/Admin@producteurs.chaincacao.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/producteurs.chaincacao.com/peers/peer0.producteurs.chaincacao.com/tls/ca.crt

rm -f ${CHANNEL_NAME}.block

MAX_RETRY=10
RETRY=0
until peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_URL -c $CHANNEL_NAME --tls --cafile $ORDERER_CA || [ $RETRY -eq $MAX_RETRY ]; do
    println "Fetch failed, retrying in 3s... ($RETRY/$MAX_RETRY)"
    if [ $RETRY -eq 2 ]; then
        println "Attempting to create channel..."
        peer channel create -o $ORDERER_URL -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --tls --cafile $ORDERER_CA
    fi
    sleep 3
    RETRY=$((RETRY+1))
done

if [ ! -f "${CHANNEL_NAME}.block" ]; then error_exit "Failed to fetch/create channel block"; fi


# 3. Join Peers
join_peer() {
    ORG=$1
    MSP=$2
    PORT=7051
    
    println "Waiting for peer0.${ORG} to open port ${PORT}..."
    TIMEOUT=30
    COUNTER=0
    until (echo > /dev/tcp/peer0.${ORG}.chaincacao.com/${PORT}) >/dev/null 2>&1 || [ $COUNTER -eq $TIMEOUT ]; do
        sleep 1
        COUNTER=$((COUNTER+1))
    done
    
    println "Joining Org ${ORG}..."
    
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_ADDRESS="peer0.${ORG}.chaincacao.com:${PORT}"
    export CORE_PEER_LOCALMSPID="${MSP}"
    export CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/peers/peer0.${ORG}.chaincacao.com/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/${ORG}.chaincacao.com/users/Admin@${ORG}.chaincacao.com/msp"
    unset CORE_PEER_TLS_CERT_FILE
    unset CORE_PEER_TLS_KEY_FILE

    set +e
    peer channel join -b ${CHANNEL_NAME}.block > join_output.log 2>&1
    RES=$?
    set -e
    
    if [ $RES -ne 0 ]; then
        if grep -q "Already joined" join_output.log; then
            println "Org ${ORG} is already joined."
        else
            cat join_output.log
            error_exit "Failed to join Org ${ORG}."
        fi
    else
        println "Org ${ORG} joined successfully."
    fi
    rm -f join_output.log

    # 4. Update Anchor Peer
    println "Updating anchor peer for ${ORG}..."
    # Capitalize first letter for filename (Producteurs vs producteurs)
    ORG_CAP=$(echo ${ORG:0:1} | tr '[:lower:]' '[:upper:]')${ORG:1}
    peer channel update -o $ORDERER_URL -c $CHANNEL_NAME -f ./channel-artifacts/Org${ORG_CAP}anchors.tx --tls --cafile $ORDERER_CA || error_exit "Failed to update anchor peer for ${ORG}"
}

join_peer "producteurs" "OrgProducteursMSP"
join_peer "exportateurs" "OrgExportateursMSP"
join_peer "certif" "OrgCertifMSP"
join_peer "ministere" "OrgMinistereMSP"
join_peer "transformateurs" "OrgTransformateursMSP"

println "${GREEN}All peers joined the channel successfully!${NC}"
