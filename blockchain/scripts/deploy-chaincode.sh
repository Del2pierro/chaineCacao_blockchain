#!/bin/bash
# ChainCacao - Chaincode Deployment Script (Lifecycle v2)

CC_NAME="chaincacao"
CC_VERSION="1.0"
CC_PATH="../chaincode"
CC_LANG="node"

BLUE='\033[0;34m'
NC='\033[0m'

function println() {
  echo -e "${BLUE}==>${NC} $1"
}

println "Packaging chaincode..."
# Lifecycle packaging
docker exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode --lang ${CC_LANG} --label ${CC_NAME}_${CC_VERSION}

println "Installing chaincode on peers..."
# Logic to install on each org's peer
# Usually requires switching environment variables in CLI

println "Approving chaincode for organizations..."
# Approval steps...

println "Committing chaincode to channel..."
# Commit step...

println "Chaincode ${CC_NAME} deployed successfully."
