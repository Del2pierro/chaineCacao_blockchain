# ChainCacao - Togo Cocoa & Coffee Traceability

## Overview
ChainCacao is a professional blockchain platform built on **Hyperledger Fabric** to ensure end-to-end traceability of cocoa and coffee supply chains in Togo. It integrates various stakeholders to provide an immutable record of product origin, certifications, and EUDR (EU Deforestation Regulation) compliance.

## Project Structure
- `application/`: (Reserved for future FastAPI Backend and Frontend)
- `blockchain/`: Core blockchain infrastructure and logic.
    - `network/`: Hyperledger Fabric network configuration (Configtx, Docker, Crypto).
    - `chaincode/`: Domain-oriented smart contracts (Node.js).
    - `scripts/`: Production-ready orchestration scripts.
    - `docs/`: Technical documentation and SDK integration guides.
    - `monitoring/`: Prometheus and Grafana configuration.

## Organizations
1. **OrgProducteursMSP**: Agricultural cooperatives and farmers.
2. **OrgExportateursMSP**: Processing and export companies.
3. **OrgCertifMSP**: Certification bodies (Fairtrade, Bio, etc.).
4. **OrgMinistereMSP**: Ministry of Agriculture (Audit & Regulation).
5. **OrgImportateursMSP**: European importers (Audit access).

## Getting Started

### 1. Prerequisites
- Docker & Docker Compose
- Hyperledger Fabric Binaries (v2.5+)
- Node.js (v14+)

### 2. Launch the Network
```bash
cd blockchain/scripts
./start-network.sh
```

### 3. Create Channel
```bash
./create-channel.sh
```

### 4. Deploy Smart Contract
```bash
./deploy-chaincode.sh
```

## Business Logic (Chaincode)
The smart contract implements:
- **CreateLot**: Initiate a new product batch.
- **AddCertification**: Link sustainability certificates.
- **TransferLotOwnership**: Record trade between actors.
- **VerifyComplianceEUDR**: Automatic check for EU regulation compliance.
- **GetLotHistory**: Full immutable audit trail.

## Production Roadmap
- [ ] Migrate to Fabric CA for dynamic identity management.
- [ ] Implement External Chaincode for easier scaling.
- [ ] Deploy Prometheus/Grafana dashboards for real-time monitoring.
- [ ] Connect FastAPI Backend using the provided `SDK_CONNECTION.md`.
