#!/bin/bash

# Couleurs pour les logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Démarrage Global de ChainCacao ===${NC}"

# 1. Lancer le réseau Blockchain
echo -e "${GREEN}1. Réinitialisation du réseau Fabric...${NC}"
cd blockchain/scripts
./reset-network.sh
if [ $? -ne 0 ]; then echo "Erreur réseau"; exit 1; fi

# 2. Création du Canal
echo -e "${GREEN}2. Création du canal et jonction des peers...${NC}"
./create-channel.sh
if [ $? -ne 0 ]; then echo "Erreur canal"; exit 1; fi

# 3. Déployer le Chaincode v1.2
echo -e "${GREEN}3. Déploiement du Smart Contract (Modular + PDC)...${NC}"
./deploy-chaincode.sh
if [ $? -ne 0 ]; then echo "Erreur déploiement"; exit 1; fi

# 4. Lancer la Gateway Node.js
echo -e "${GREEN}4. Lancement de la Gateway API (Node.js)...${NC}"
cd ../gateway
npm install # Au cas où
node index.js > gateway.log 2>&1 &
GATEWAY_PID=$!
echo "Gateway lancée avec le PID: $GATEWAY_PID"

# 5. Lancer le Backend FastAPI
echo -e "${GREEN}5. Lancement du Backend (Python/FastAPI)...${NC}"
cd ../../backend
# Assure-toi d'avoir ton venv activé si nécessaire
pip install -r requirements.txt > /dev/null
uvicorn main:app --reload --host 0.0.0.0 --port 8000 > backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend lancé avec le PID: $BACKEND_PID"

echo -e "${BLUE}=== Système prêt ! ===${NC}"
echo "API Swagger : http://localhost:8000/docs"
echo "Pour tout arrêter : kill $GATEWAY_PID $BACKEND_PID && cd ../blockchain/network && docker-compose down"

# Garder le script en vie pour voir les logs si besoin ou simplement attendre
wait