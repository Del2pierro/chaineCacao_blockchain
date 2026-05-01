#!/bin/bash
# ChainCacao - Network Start Script

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd "$DIR/.." && pwd)"

export PATH="$ROOT_DIR/../bin:$PATH"
# cd into the network directory so that relative paths in config files (like configtx.yaml) resolve correctly
cd "$ROOT_DIR/network" || error_exit "Failed to cd into $ROOT_DIR/network"

export FABRIC_CFG_PATH="$ROOT_DIR/network"
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

function wait_for_healthy() {
    local container=$1
    println "Waiting for $container to be ready..."
    while [ "$(docker inspect -f '{{.State.Health.Status}}' $container 2>/dev/null)" != "healthy" ]; do
        printf "."
        sleep 2
    done
    echo ""
    println "Container $container is READY."
}

# Check if network is already bootstrapped
BOOTSTRAPPED=true
if [ ! -d "../organizations/peerOrganizations" ]; then
    BOOTSTRAPPED=false
fi
if [ ! -f "./system-genesis-block/genesis.block" ]; then
    BOOTSTRAPPED=false
fi

if [ "$BOOTSTRAPPED" = true ]; then
    println "Network artifacts found. Resuming existing network..."
    docker-compose up -d || error_exit "Failed to start docker containers"
else
    println "Network not bootstrapped. Starting fresh deployment..."
    
    println "Cleaning up existing containers (if any)..."
    docker-compose down --remove-orphans

    println "Starting Fabric CA containers..."
    docker-compose up -d ca_producteurs ca_exportateurs ca_certif ca_ministere ca_transformateurs ca_orderer || error_exit "Failed to start CA containers"

    wait_for_healthy ca_producteurs
    wait_for_healthy ca_orderer

    println "Registering identities via Fabric CA..."
    bash ../scripts/register-identities.sh || error_exit "Failed to register identities"

    println "Creating System Genesis Block..."
    if [ ! -d "./system-genesis-block" ]; then
        mkdir -p ./system-genesis-block
    fi
    configtxgen -profile ChainCacaoOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block || error_exit "Failed to generate genesis block"

    println "Starting remaining Network Nodes..."
    docker-compose up -d || error_exit "Failed to start docker containers"
fi

println "Network is UP. Checking health..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

