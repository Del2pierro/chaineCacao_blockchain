#!/bin/bash
# Bootstrap script to download Hyperledger Fabric binaries

set -e

FABRIC_VERSION=${1:-2.5.0}
FABRIC_CA_VERSION=${2:-1.5.0}

echo "Downloading Hyperledger Fabric v${FABRIC_VERSION}..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FABRIC_BIN_DIR="${SCRIPT_DIR}/../bin"

# Create bin directory
mkdir -p "$FABRIC_BIN_DIR"

# Platform detection
PLATFORM=$(uname -s)
case "$PLATFORM" in
    Linux)
        ARCH=linux-amd64
        ;;
    Darwin)
        ARCH=darwin-amd64
        ;;
    MINGW*|MSYS*|CYGWIN*)
        ARCH=windows-amd64
        ;;
    *)
        echo "Unsupported platform: $PLATFORM"
        exit 1
        ;;
esac

# Download Fabric binaries
FABRIC_URL="https://github.com/hyperledger/fabric/releases/download/v${FABRIC_VERSION}/hyperledger-fabric-${ARCH}-${FABRIC_VERSION}.tar.gz"
echo "Downloading from: $FABRIC_URL"

cd "$FABRIC_BIN_DIR"
if command -v wget &> /dev/null; then
    wget -O fabric-${FABRIC_VERSION}.tar.gz "$FABRIC_URL"
elif command -v curl &> /dev/null; then
    curl -L -O "$FABRIC_URL" -o fabric-${FABRIC_VERSION}.tar.gz
else
    echo "Error: Neither wget nor curl found. Please install one of them."
    exit 1
fi

# Extract binaries
tar -xzf fabric-${FABRIC_VERSION}.tar.gz
rm fabric-${FABRIC_VERSION}.tar.gz

# Download Fabric CA binaries
FABRIC_CA_URL="https://github.com/hyperledger/fabric-ca/releases/download/v${FABRIC_CA_VERSION}/hyperledger-fabric-ca-${ARCH}-${FABRIC_CA_VERSION}.tar.gz"
echo "Downloading Fabric CA from: $FABRIC_CA_URL"

if command -v wget &> /dev/null; then
    wget -O fabric-ca-${FABRIC_CA_VERSION}.tar.gz "$FABRIC_CA_URL"
elif command -v curl &> /dev/null; then
    curl -L "$FABRIC_CA_URL" -o fabric-ca-${FABRIC_CA_VERSION}.tar.gz
fi

tar -xzf fabric-ca-${FABRIC_CA_VERSION}.tar.gz
rm fabric-ca-${FABRIC_CA_VERSION}.tar.gz

echo "✓ Hyperledger Fabric binaries downloaded successfully to $FABRIC_BIN_DIR"
echo "Available commands:"
ls -la "$FABRIC_BIN_DIR" | grep -E 'configtxgen|cryptogen|orderer|peer'
