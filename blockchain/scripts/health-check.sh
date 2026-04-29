#!/bin/bash
# ChainCacao - Network Health Check

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Checking ChainCacao Infrastructure...${NC}"

# Check Docker containers
containers=("orderer.chaincacao.com" "peer0.producteurs.chaincacao.com" "peer0.exportateurs.chaincacao.com" "peer0.certif.chaincacao.com" "peer0.ministere.chaincacao.com" "peer0.importateurs.chaincacao.com")

for container in "${containers[@]}"; do
    if [ "$(docker inspect -f '{{.State.Running}}' $container 2>/dev/null)" == "true" ]; then
        echo -e "  [${GREEN}OK${NC}] $container is running"
    else
        echo -e "  [${RED}FAIL${NC}] $container is NOT running"
    fi
done

# Check CouchDB
if curl -s http://localhost:5984 > /dev/null; then
    echo -e "  [${GREEN}OK${NC}] CouchDB OrgProducteurs is responsive"
else
    echo -e "  [${RED}FAIL${NC}] CouchDB OrgProducteurs is NOT responsive"
fi

echo -e "${BLUE}Health Check Complete.${NC}"
