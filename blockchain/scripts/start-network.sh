#!/bin/bash
# ChainCacao - Network Start Script

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../network
export VERBOSE=false

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

function println() {
  echo -e "${BLUE}==>${NC} $1"
}

function error_exit() {
  echo -e "${RED}Error:${NC} $1"
  exit 1
}

println "Cleaning up existing containers and artifacts..."
docker-compose -f ../network/docker-compose.yaml down --volumes --remove-orphans

println "Generating crypto material using cryptogen..."
if [ ! -d "../organizations" ]; then
    mkdir -p ../organizations
fi

cryptogen generate --config=../network/crypto-config.yaml --output="../organizations" || error_exit "Failed to generate crypto material"

println "Creating System Genesis Block..."
if [ ! -d "../network/system-genesis-block" ]; then
    mkdir -p ../network/system-genesis-block
fi

configtxgen -profile ChainCacaoOrdererGenesis -channelID system-channel -outputBlock ../network/system-genesis-block/genesis.block || error_exit "Failed to generate genesis block"

println "Starting Network Nodes..."
docker-compose -f ../network/docker-compose.yaml up -d || error_exit "Failed to start docker containers"

println "Network is UP. Checking health..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
