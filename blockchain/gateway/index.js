const express = require('express');
const grpc = require('@grpc/grpc-js');
const { connect, hash } = require('@hyperledger/fabric-gateway');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
const IdentityService = require('./IdentityService');

const app = express();
app.use(express.json());

const ORGS_ROOT = path.resolve(__dirname, process.env.ORGS_ROOT || '../organizations');
const identityService = new IdentityService(ORGS_ROOT);

// gRPC connection details from .env
const PEER_ENDPOINT = process.env.PEER_ENDPOINT || 'localhost:7051';
const PEER_HOST_ALIAS = process.env.PEER_HOST_ALIAS || 'peer0.producteurs.chaincacao.com';
const CHANNEL_NAME = process.env.CHANNEL_NAME || 'chaincacaochannel';
const CHAINCODE_NAME = process.env.CHAINCODE_NAME || 'chaincacao';


async function getGatewayConnection(orgName, userId) {
    const identity = await identityService.getIdentity(orgName, userId);
    
    const tlsCertPath = path.join(ORGS_ROOT, 'peerOrganizations', `${orgName}.chaincacao.com`, 'peers', `peer0.${orgName}.chaincacao.com`, 'tls', 'ca.crt');
    const tlsRootCert = fs.readFileSync(tlsCertPath);

    const client = new grpc.Client(PEER_ENDPOINT, grpc.credentials.createSsl(tlsRootCert), {
        'grpc.ssl_target_name_override': PEER_HOST_ALIAS,
    });

    return {
        gateway: connect({
            client,
            identity: { mspId: identity.mspId, credentials: identity.credentials },
            signer: (digest) => {
                const sign = require('crypto').createSign('sha256');
                sign.update(digest);
                return sign.sign(identity.privateKey);
            },
            evaluateOptions: () => ({ deadline: Date.now() + 5000 }),
            endorseOptions: () => ({ deadline: Date.now() + 15000 }),
            submitOptions: () => ({ deadline: Date.now() + 15000 }),
            commitStatusOptions: () => ({ deadline: Date.now() + 60000 }),
        }),
        client
    };
}

app.post('/invoke', async (req, res) => {
    const { function: fn, args } = req.body;
    const orgName = req.header('X-Org-Name') || 'producteurs';
    const userId = req.header('X-User-ID') || 'Admin';

    let connection;
    try {
        connection = await getGatewayConnection(orgName, userId);
        const network = connection.gateway.getNetwork(CHANNEL_NAME);
        const contract = network.getContract(CHAINCODE_NAME);

        console.log(`Invoking ${fn} as ${userId}@${orgName}...`);
        const resultBytes = await contract.submitTransaction(fn, ...args);
        const result = Buffer.from(resultBytes).toString();

        res.json({ success: true, result: result ? JSON.parse(result) : null });
    } catch (error) {
        console.error('Transaction error:', error);
        res.status(500).json({ success: false, error: error.message });
    } finally {
        if (connection) connection.client.close();
    }
});

app.post('/query', async (req, res) => {
    const { function: fn, args } = req.body;
    const orgName = req.header('X-Org-Name') || 'producteurs';
    const userId = req.header('X-User-ID') || 'Admin';

    let connection;
    try {
        connection = await getGatewayConnection(orgName, userId);
        const network = connection.gateway.getNetwork(CHANNEL_NAME);
        const contract = network.getContract(CHAINCODE_NAME);

        console.log(`Querying ${fn} as ${userId}@${orgName}...`);
        const resultBytes = await contract.evaluateTransaction(fn, ...args);
        const result = Buffer.from(resultBytes).toString();

        res.json({ success: true, result: result ? JSON.parse(result) : null });
    } catch (error) {
        console.error('Query error:', error);
        res.status(500).json({ success: false, error: error.message });
    } finally {
        if (connection) connection.client.close();
    }
});

app.post('/register', async (req, res) => {
    const { userId, orgName, role } = req.body;
    
    try {
        console.log(`Registering new user ${userId} in ${orgName}...`);
        const result = await identityService.registerAndEnrollUser(orgName, userId, role);
        res.json(result);
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`🚀 Gateway API listening on port ${PORT}`);
});
