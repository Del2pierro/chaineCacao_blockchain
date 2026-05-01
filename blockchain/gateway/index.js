const express = require('express');
const grpc = require('@grpc/grpc-js');
const { connect, signers } = require('@hyperledger/fabric-gateway');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
const IdentityService = require('./IdentityService');

const app = express();
app.use(express.json());

const ORGS_ROOT = path.resolve(__dirname, process.env.ORGS_ROOT || '../organizations');
const CHANNEL_NAME = process.env.CHANNEL_NAME || 'chaincacaochannel';
const CHAINCODE_NAME = process.env.CHAINCODE_NAME || 'chaincacao';
const identityService = new IdentityService(ORGS_ROOT);

// gRPC connection details from .env
const crypto = require('crypto');

const ORGS_CONFIG = {
    'producteurs': { port: 7051, mspId: 'OrgProducteursMSP' },
    'exportateurs': { port: 8051, mspId: 'OrgExportateursMSP' },
    'certif': { port: 9051, mspId: 'OrgCertifMSP' },
    'ministere': { port: 10051, mspId: 'OrgMinistereMSP' },
    'transformateurs': { port: 11051, mspId: 'OrgTransformateursMSP' }
};

async function getGatewayConnection(orgName, userId = 'admin') {
    const identity = await identityService.getIdentity(orgName, userId);
    const privateKey = crypto.createPrivateKey(identity.credentials.privateKey);

    // Primary connection (the one we use as entry point)
    const primaryOrg = ORGS_CONFIG[orgName];
    const tlsCertPath = path.join(ORGS_ROOT, 'peerOrganizations', `${orgName}.chaincacao.com`, 'peers', `peer0.${orgName}.chaincacao.com`, 'tls', 'ca.crt');
    const tlsRootCert = fs.readFileSync(tlsCertPath);

    const client = new grpc.Client(`localhost:${primaryOrg.port}`, grpc.credentials.createSsl(tlsRootCert), {
        'grpc.ssl_target_name_override': `peer0.${orgName}.chaincacao.com`,
    });

    return {
        gateway: connect({
            client,
            identity: { 
                mspId: identity.mspId, 
                credentials: Buffer.from(identity.credentials.certificate) 
            },
            signer: signers.newPrivateKeySigner(privateKey),
            // For production-ready: we trust the discovery but as we are in dev/localhost, 
            // we ensure the primary client is used. 
            // In a real production environment, 'client' would be a load balancer or we'd use Discovery with proper DNS.
            discovery: { enabled: true, asLocalhost: true },
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
    const userId = req.header('X-User-ID') || 'admin';

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
        if (error.details) console.error('Error details:', error.details);
        if (error.cause) console.error('Error cause:', error.cause);
        res.status(500).json({ 
            success: false, 
            error: error.message,
            details: error.details || null 
        });
    } finally {
        if (connection) connection.client.close();
    }
});

app.post('/query', async (req, res) => {
    const { function: fn, args } = req.body;
    const orgName = req.header('X-Org-Name') || 'producteurs';
    const userId = req.header('X-User-ID') || 'admin';

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
