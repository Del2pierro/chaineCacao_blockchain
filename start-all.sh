#!/bin/bash
# ChainCacao - Script de Lancement Production

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Lancement de l'Infrastructure ChainCacao ===${NC}"

# 0. Nettoyage des ports (Windows/GitBash)
echo -e "${BLUE}0. Libération des ports 3000 et 8000...${NC}"
powershell.exe -Command "Get-NetTCPConnection -LocalPort 3000, 8000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" 2>/dev/null || true

# 1. Démarrage du Réseau Blockchain
echo -e "${GREEN}1. Initialisation du réseau Fabric (Enterprise Mode)...${NC}"
cd blockchain/scripts
./reset-network.sh > setup.log 2>&1
if [ $? -ne 0 ]; then echo "Erreur réseau (voir blockchain/scripts/setup.log)"; exit 1; fi

# 2. Création du Canal
echo -e "${GREEN}2. Configuration du canal...${NC}"
./create-channel.sh >> setup.log 2>&1
if [ $? -ne 0 ]; then echo "Erreur canal (voir blockchain/scripts/setup.log)"; exit 1; fi

# 3. Déploiement du Smart Contract
echo -e "${GREEN}3. Déploiement du Smart Contract...${NC}"
./deploy-chaincode.sh >> setup.log 2>&1
if [ $? -ne 0 ]; then echo "Erreur déploiement (voir blockchain/scripts/setup.log)"; exit 1; fi

# 4. Lancement de la Gateway Node.js
echo -e "${GREEN}4. Lancement de la Gateway API...${NC}"
cd ../gateway
npm install --quiet
npm start > gateway.log 2>&1 &
GATEWAY_PID=$!

# 5. Lancement du Backend FastAPI (Mode Production)
echo -e "${GREEN}5. Lancement du Backend FastAPI...${NC}"
cd ../../backend
# Activation de l'environnement virtuel (créé via Git Bash)
source ../env/Scripts/activate
python -m pip install -r requirements.txt --quiet
python -m uvicorn main:app --host 0.0.0.0 --port 8000 > backend.log 2>&1 &
BACKEND_PID=$!

echo -e "${BLUE}=== Système opérationnel ===${NC}"
echo "API Swagger : http://localhost:8000/docs"
echo "Gateway PID: $GATEWAY_PID | Backend PID: $BACKEND_PID"

# Garder le script en vie
wait