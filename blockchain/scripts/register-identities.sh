#!/bin/bash

# Script pour enrôler les identités via Fabric CA au lieu de cryptogen
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCKCHAIN_DIR="$(dirname "$SCRIPT_DIR")"
export PATH="$BLOCKCHAIN_DIR/bin:$PATH"

# Load environment variables
if [ -f "$BLOCKCHAIN_DIR/network/.env" ]; then
    source "$BLOCKCHAIN_DIR/network/.env"
else
    echo "Warning: .env file not found in $BLOCKCHAIN_DIR/network/"
fi

# Configuration des ports CA
CA_PORT_PRODUCTEURS=7054
CA_PORT_EXPORTATEURS=8054
CA_PORT_CERTIF=9054
CA_PORT_MINISTERE=10054
CA_PORT_TRANSFORMATEURS=11054
CA_PORT_ORDERER=12054

function createNodeOUConfig() {
    local msp_dir=$1
    echo "Creating config.yaml for NodeOUs in $msp_dir..."
    cat <<EOF > "$msp_dir/config.yaml"
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
}

function enrollAdmin() {
    local org=$1
    local port=$2
    echo "Enrolling CA Admin for $org..."
    
    ORG_DIR="$BLOCKCHAIN_DIR/organizations/peerOrganizations/${org}.chaincacao.com"
    mkdir -p "$ORG_DIR"

    export FABRIC_CA_CLIENT_HOME="$ORG_DIR"
    
    CA_CERT="$BLOCKCHAIN_DIR/organizations/fabric-ca/${org}/ca-cert.pem"
    
    # Wait for CA cert
    until [ -f "$CA_CERT" ]; do
        echo "Waiting for $CA_CERT..."
        sleep 2
    done

    # Enroll CA Registrar (admin)
    fabric-ca-client enroll -u https://${CA_ADMIN_NAME}:${CA_ADMIN_PASSWORD}@localhost:${port} --caname ca-${org} --tls.certfiles "$CA_CERT"

    # Set up MSP folder structure
    mkdir -p "$ORG_DIR/msp/cacerts"
    mkdir -p "$ORG_DIR/msp/tlscacerts"
    cp "$CA_CERT" "$ORG_DIR/msp/cacerts/"
    cp "$CA_CERT" "$ORG_DIR/msp/tlscacerts/"

    # Create config.yaml for NodeOUs
    createNodeOUConfig "$ORG_DIR/msp"

    echo "Registering & Enrolling Organization Admin for $org..."
    # Register Org Admin
    fabric-ca-client register --caname ca-${org} --id.name orgAdmin --id.secret ${ORG_ADMIN_PASSWORD} --id.type admin --tls.certfiles "$CA_CERT"
    
    # Enroll Org Admin into the "users" folder
    ADMIN_DIR="$ORG_DIR/users/Admin@${org}.chaincacao.com"
    mkdir -p "$ADMIN_DIR"
    fabric-ca-client enroll -u https://orgAdmin:${ORG_ADMIN_PASSWORD}@localhost:${port} --caname ca-${org} -M "$ADMIN_DIR/msp" --tls.certfiles "$CA_CERT"

    # Set up admincerts for the User Admin MSP
    mkdir -p "$ADMIN_DIR/msp/admincerts"
    cp "$ADMIN_DIR/msp/signcerts/"* "$ADMIN_DIR/msp/admincerts/"

    # Also for the Organization MSP
    mkdir -p "$ORG_DIR/msp/admincerts"
    cp "$ADMIN_DIR/msp/signcerts/"* "$ORG_DIR/msp/admincerts/"
}

function registerPeer() {
    local org=$1
    local port=$2
    echo "Registering and Enrolling Peer0 for $org..."
    
    ORG_DIR="$BLOCKCHAIN_DIR/organizations/peerOrganizations/${org}.chaincacao.com"
    export FABRIC_CA_CLIENT_HOME="$ORG_DIR"
    CA_CERT="$BLOCKCHAIN_DIR/organizations/fabric-ca/${org}/ca-cert.pem"

    # Register peer
    fabric-ca-client register --caname ca-${org} --id.name peer0 --id.secret ${PEER_PASSWORD} --id.type peer --tls.certfiles "$CA_CERT"

    # Enroll peer
    PEER_DIR="$ORG_DIR/peers/peer0.${org}.chaincacao.com"
    mkdir -p "$PEER_DIR"
    fabric-ca-client enroll -u https://peer0:${PEER_PASSWORD}@localhost:${port} --caname ca-${org} -M "$PEER_DIR/msp" --csr.hosts peer0.${org}.chaincacao.com --tls.certfiles "$CA_CERT"

    # Set up Peer TLS folders
    mkdir -p "$PEER_DIR/tls"
    cp "$PEER_DIR/msp/signcerts/"* "$PEER_DIR/tls/server.crt"
    cp "$PEER_DIR/msp/keystore/"* "$PEER_DIR/tls/server.key"
    cp "$CA_CERT" "$PEER_DIR/tls/ca.crt"
    
    mkdir -p "$PEER_DIR/msp/tlscacerts"
    cp "$CA_CERT" "$PEER_DIR/msp/tlscacerts/"

    # Copy Org Admin cert to Peer MSP (Required to validate admin commands)
    ADMIN_CERT="$ORG_DIR/users/Admin@${org}.chaincacao.com/msp/signcerts/"*
    mkdir -p "$PEER_DIR/msp/admincerts"
    cp $ADMIN_CERT "$PEER_DIR/msp/admincerts/"
}

function registerOrderer() {
    local port=$1
    echo "Registering & Enrolling Orderer..."

    ORDERER_DIR="$BLOCKCHAIN_DIR/organizations/ordererOrganizations/chaincacao.com"
    mkdir -p "$ORDERER_DIR"
    export FABRIC_CA_CLIENT_HOME="$ORDERER_DIR"
    CA_CERT="$BLOCKCHAIN_DIR/organizations/fabric-ca/orderer/ca-cert.pem"
    
    until [ -f "$CA_CERT" ]; do
        echo "Waiting for $CA_CERT..."
        sleep 2
    done

    # Enroll CA Registrar (admin) for Orderer
    fabric-ca-client enroll -u https://${CA_ADMIN_NAME}:${CA_ADMIN_PASSWORD}@localhost:${port} --caname ca-orderer --tls.certfiles "$CA_CERT"

    # Register orderer identity
    fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ${ORDERER_PASSWORD} --id.type orderer --tls.certfiles "$CA_CERT"

    # Enroll orderer node
    NODE_DIR="$ORDERER_DIR/orderers/orderer.chaincacao.com"
    mkdir -p "$NODE_DIR"
    fabric-ca-client enroll -u https://orderer:${ORDERER_PASSWORD}@localhost:${port} --caname ca-orderer -M "$NODE_DIR/msp" --csr.hosts orderer.chaincacao.com --tls.certfiles "$CA_CERT"

    # Set up Orderer TLS folder
    mkdir -p "$NODE_DIR/tls"
    cp "$NODE_DIR/msp/signcerts/"* "$NODE_DIR/tls/server.crt"
    cp "$NODE_DIR/msp/keystore/"* "$NODE_DIR/tls/server.key"
    cp "$CA_CERT" "$NODE_DIR/tls/ca.crt"

    # Standardize MSP folders for Node
    mkdir -p "$NODE_DIR/msp/tlscacerts"
    cp "$CA_CERT" "$NODE_DIR/msp/tlscacerts/"
    mkdir -p "$NODE_DIR/msp/cacerts"
    cp "$CA_CERT" "$NODE_DIR/msp/cacerts/"

    # Create config.yaml for Orderer
    createNodeOUConfig "$ORDERER_DIR/msp"

    # CRUCIAL: Orderer also needs admincerts to start
    mkdir -p "$NODE_DIR/msp/admincerts"
    cp "$ORDERER_DIR/msp/signcerts/"* "$NODE_DIR/msp/admincerts/"

    # Standardize Top-level Orderer MSP
    mkdir -p "$ORDERER_DIR/msp/tlscacerts"
    cp "$CA_CERT" "$ORDERER_DIR/msp/tlscacerts/"
    mkdir -p "$ORDERER_DIR/msp/cacerts"
    cp "$CA_CERT" "$ORDERER_DIR/msp/cacerts/"
    mkdir -p "$ORDERER_DIR/msp/admincerts"
    cp "$ORDERER_DIR/msp/signcerts/"* "$ORDERER_DIR/msp/admincerts/"
}

# Main Execution
echo "Starting Identity Registration via Fabric CA..."

enrollAdmin "producteurs" ${CA_PORT_PRODUCTEURS}
registerPeer "producteurs" ${CA_PORT_PRODUCTEURS}

enrollAdmin "exportateurs" ${CA_PORT_EXPORTATEURS}
registerPeer "exportateurs" ${CA_PORT_EXPORTATEURS}

enrollAdmin "certif" ${CA_PORT_CERTIF}
registerPeer "certif" ${CA_PORT_CERTIF}

enrollAdmin "ministere" ${CA_PORT_MINISTERE}
registerPeer "ministere" ${CA_PORT_MINISTERE}

enrollAdmin "transformateurs" ${CA_PORT_TRANSFORMATEURS}
registerPeer "transformateurs" ${CA_PORT_TRANSFORMATEURS}

registerOrderer ${CA_PORT_ORDERER}

echo "Identity Registration Completed Successfully!"
