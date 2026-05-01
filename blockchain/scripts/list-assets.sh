#!/bin/bash
# ChainCacao - Listing and Query Script

CHANNEL_NAME="chaincacaochannel"
CC_NAME="chaincacao"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

println() {
  echo -e "${BLUE}==>${NC} $1"
}

println "Querying all lots from CouchDB..."
docker exec cli peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"GetAllLots","Args":[]}' | jq .

println "Querying specific lot LOT_2024_001..."
docker exec cli peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"GetLot","Args":["LOT_2024_001"]}' | jq .

println "Fetching history for asset LOT_2024_001..."
docker exec cli peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"function":"GetHistoryForAsset","Args":["LOT_2024_001"]}' | jq .

println "${GREEN}Queries completed.${NC}"
