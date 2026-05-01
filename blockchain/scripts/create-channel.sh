#!/bin/bash
# ChainCacao - Channel Creation Script

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd "$DIR/.." && pwd)"

export PATH="$ROOT_DIR/../bin:$PATH"
export FABRIC_CFG_PATH="$ROOT_DIR/network"
CHANNEL_NAME="chaincacaochannel"

BLUE='\033[0;34m'
NC='\033[0m'

function println() {
  echo -e "${BLUE}==>${NC} $1"
}

function error_exit() {
  echo -e "\033[0;31mError:\033[0m $1"
  exit 1
}

# cd into the network directory so that relative paths in config files work
cd "$ROOT_DIR/network" || error_exit "Failed to cd into $ROOT_DIR/network"

println "Generating Channel Artifacts..."
if [ ! -d "./channel-artifacts" ]; then
    mkdir -p ./channel-artifacts
fi

configtxgen -profile ChainCacaoChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME} || error_exit "Failed to generate channel transaction"

# Generate Anchor Peer Transactions
for org in Producteurs Exportateurs Certif Ministere Transformateurs; do
    println "Generating anchor peer update for Org${org}..."
    configtxgen -profile ChainCacaoChannel -outputAnchorPeersUpdate ./channel-artifacts/Org${org}anchors.tx -channelID ${CHANNEL_NAME} -asOrg Org${org}MSP || error_exit "Failed for Org${org}"
done

println "Joining peers to channel ${CHANNEL_NAME}..."
docker exec cli ./scripts/internal-channel-join.sh || error_exit "Failed to join peers to channel"

