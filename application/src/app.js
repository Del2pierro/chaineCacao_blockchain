'use strict';

const express = require('express');
const { connect, hashOpt, signable } = require('@hyperledger/fabric-gateway');
const grpc = require('@grpc/grpc-js');
const crypto = require('crypto');
const fs = require('fs/promises');
const path = require('path');
require('dotenv').config();

const app = express();
app.use(express.json());

const {
    CHANNEL_NAME,
    CHAINCODE_NAME,
    MSP_ID,
    PEER_ENDPOINT,
    PEER_HOST_ALIAS,
    KEY_DIR_PATH,
    CERT_PATH,
    TLS_CERT_PATH,
    API_PORT
} = process.env;

async function newGrpcConnection() {
    const tlsRootCert = await fs.readFile(TLS_CERT_PATH);
    const tlsCredentials = grpc.credentials.createSsl(tlsRootCert);
    return new grpc.Client(PEER_ENDPOINT, tlsCredentials, {
        'grpc.ssl_target_name_override': PEER_HOST_ALIAS,
    });
}

async function newIdentity() {
    const credentials = await fs.readFile(CERT_PATH);
    return { mspId: MSP_ID, credentials };
}

async function newSigner() {
    const files = await fs.readdir(KEY_DIR_PATH);
    const keyPath = path.resolve(KEY_DIR_PATH, files[0]);
    const privateKeyPem = await fs.readFile(keyPath);
    const privateKey = crypto.createPrivateKey(privateKeyPem);
    return signable.fromPrivateKey(privateKey);
}

// Global Gateway variables
let gateway;
let network;
let contract;

async function initGateway() {
    const client = await newGrpcConnection();
    gateway = connect({
        client,
        identity: await newIdentity(),
        signer: await newSigner(),
        evaluateOptions: () => ({ deadline: Date.now() + 5000 }),
        submitOptions: () => ({ deadline: Date.now() + 30000 }),
    });
    network = gateway.getNetwork(CHANNEL_NAME);
    contract = network.getContract(CHAINCODE_NAME);
}

// API Routes

// Create a Lot
app.post('/api/lots', async (req, res) => {
    try {
        const { idLot, typeProduit, origine, proprietaire } = req.body;
        const result = await contract.submitTransaction('CréationLot', idLot, typeProduit, origine, proprietaire);
        res.json({ success: true, data: JSON.parse(result.toString()) });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Get Lot details
app.get('/api/lots/:id', async (req, res) => {
    try {
        const result = await contract.evaluateTransaction('ObtenirLot', req.params.id);
        res.json({ success: true, data: JSON.parse(result.toString()) });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Update Status
app.put('/api/lots/:id/status', async (req, res) => {
    try {
        const { statut } = req.body;
        const result = await contract.submitTransaction('MiseAJourStatut', req.params.id, statut);
        res.json({ success: true, data: JSON.parse(result.toString()) });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Transfer Ownership
app.put('/api/lots/:id/transfer', async (req, res) => {
    try {
        const { nouveauProprietaire } = req.body;
        const result = await contract.submitTransaction('TransfertPropriété', req.params.id, nouveauProprietaire);
        res.json({ success: true, data: JSON.parse(result.toString()) });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Get History
app.get('/api/lots/:id/history', async (req, res) => {
    try {
        const result = await contract.evaluateTransaction('HistoriqueLot', req.params.id);
        res.json({ success: true, data: JSON.parse(result.toString()) });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Start server
const port = API_PORT || 3000;
initGateway().then(() => {
    app.listen(port, () => {
        console.log(`🚀 ChainCacao API running at http://localhost:${port}`);
    });
}).catch(err => {
    console.error('❌ Failed to connect to Fabric Gateway:', err);
});
