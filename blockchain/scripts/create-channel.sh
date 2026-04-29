#!/bin/bash
# ChainCacao - Channel Creation Script

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../network
CHANNEL_NAME="chaincacaochannel"

BLUE='\033[0;34m'
NC='\033[0m'

function println() {
  echo -e "${BLUE}==>${NC} $1"
}

println "Generating Channel Artifacts..."
if [ ! -d "../network/channel-artifacts" ]; then
    mkdir ../network/channel-artifacts
fi

configtxgen -profile ChainCacaoChannel -outputCreateChannelTx ../network/channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}

println "Joining peers to channel ${CHANNEL_NAME}..."
# This script usually runs inside the CLI or uses peer commands with appropriate environment variables.
# For simplicity, we assume CLI is used for this orchestration step.

docker exec cli ./scripts/internal-channel-join.sh
