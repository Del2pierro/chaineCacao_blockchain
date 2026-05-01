        #!/bin/bash
        # ChainCacao - Complete Network Reset and Startup Script

        set -e

        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
        BLOCKCHAIN_DIR="$PROJECT_ROOT"
        NETWORK_DIR="$BLOCKCHAIN_DIR/network"
        SCRIPTS_DIR="$BLOCKCHAIN_DIR/scripts"

        # Colors
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        BLUE='\033[0;34m'
        NC='\033[0m'

        println() {
        echo -e "${BLUE}==>${NC} $1"
        }

        success() {
        echo -e "${GREEN}✓${NC} $1"
        }

        error() {
        echo -e "${RED}Error:${NC} $1"
        exit 1
        }

        # Check if Fabric binaries exist
        check_fabric_binaries() {
        # Check in local bin or system PATH
        if [ -d "$BLOCKCHAIN_DIR/bin" ]; then
            export PATH="$BLOCKCHAIN_DIR/bin:$PATH"
        fi

        export FABRIC_CFG_PATH="$NETWORK_DIR"

        if ! command -v fabric-ca-client &> /dev/null; then
            error "fabric-ca-client not found. Please install Fabric CA binaries."
        fi

        if ! command -v configtxgen &> /dev/null; then
            error "configtxgen not found. Please install Fabric binaries."
        fi

        }

        # Clean up existing containers and artifacts
        cleanup() {
        println "Cleaning up existing containers and artifacts..."

        # Stop and remove containers
        docker-compose -f "$NETWORK_DIR/docker-compose.yaml" down --volumes --remove-orphans 2>/dev/null || true

        # Remove crypto materials and genesis block
        rm -rf "$BLOCKCHAIN_DIR/organizations"
        rm -rf "$NETWORK_DIR/system-genesis-block"

        # Remove Docker volumes
        docker volume rm $(docker volume ls -q | grep chaincacao) 2>/dev/null || true

        success "Cleanup completed"
        }

        # Generate crypto materials using Fabric CA
        generate_crypto() {
        println "Generating crypto material using Fabric CA..."

        # 1. Start CAs first
        docker-compose -f "$NETWORK_DIR/docker-compose.yaml" up -d \
            ca.producteurs.chaincacao.com \
            ca.exportateurs.chaincacao.com \
            ca.certif.chaincacao.com \
            ca.ministere.chaincacao.com \
            ca.transformateurs.chaincacao.com \
            ca.orderer.chaincacao.com


        
        println "Waiting for CAs to start (port 7054)..."
        MAX_RETRY=15
        COUNT=0
        while [ $COUNT -lt $MAX_RETRY ]; do
            if nc -z 127.0.0.1 7054 2>/dev/null; then
                success "CAs are up!"
                sleep 2 # Extra safety
                break
            fi
            echo "Waiting ($COUNT/$MAX_RETRY)..."
            sleep 2
            COUNT=$((COUNT+1))
        done

        if [ $COUNT -eq $MAX_RETRY ]; then
            error "CAs failed to start. Check logs with: docker logs ca_producteurs"
        fi



        # 2. Run the registration script
        chmod +x "$SCRIPTS_DIR/register-identities.sh"
        "$SCRIPTS_DIR/register-identities.sh" || error "Failed to register identities via CA"

        success "Crypto material generated via CA"
        }

        # Start network (the rest of the nodes)
        start_network() {
        println "Starting remaining Network Nodes (Orderers, Peers)..."

        docker-compose -f "$NETWORK_DIR/docker-compose.yaml" up -d \
            || error "Failed to start remaining docker containers"


        println "Network is UP. Checking health..."
        sleep 5

        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true

        success "Network started successfully"

        }

        # Main execution
        # Generate genesis block
        generate_genesis() {
        println "Creating System Genesis Block..."

        mkdir -p "$NETWORK_DIR/system-genesis-block"

        configtxgen \
            -profile ChainCacaoOrdererGenesis \
            -channelID system-channel \
            -outputBlock "$NETWORK_DIR/system-genesis-block/genesis.block" \
            || error "Failed to generate genesis block"

        success "Genesis block created"
        }

        # Main execution
        main() {
        println "ChainCacao Network - Complete Reset and Startup (Enterprise Mode: CA)"
        println "================================================="

        check_fabric_binaries
        cleanup
        generate_crypto   # This now starts CAs and runs registration
        generate_genesis
        start_network

        println ""
        success "ChainCacao network is ready (Enterprise Mode: CA)!"
        println "Next steps:"
        echo "  1. Create channel: ./scripts/create-channel.sh"
        echo "  2. Deploy chaincode: ./scripts/deploy-chaincode.sh"
        }
        main "$@"

