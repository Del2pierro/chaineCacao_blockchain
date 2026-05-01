const FabricCAServices = require('fabric-ca-client');
const { Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');

class IdentityService {
    constructor(orgsRoot) {
        this.orgsRoot = orgsRoot;
        // Map of Org Name to CA URL and Port
        this.caConfigs = {
            'producteurs': 'https://localhost:7054',
            'exportateurs': 'https://localhost:8054',
            'certif': 'https://localhost:9054',
            'ministere': 'https://localhost:10054',
            'transformateurs': 'https://localhost:11054'
        };



    }

    async getWallet(orgName) {
        const walletPath = path.join(this.orgsRoot, 'wallets', orgName);
        console.log(`Using wallet path: ${walletPath}`);
        return await Wallets.newFileSystemWallet(walletPath);
    }

    async getIdentity(orgName, userId = 'admin') {
        console.log(`Getting identity for ${userId} in ${orgName}...`);
        const wallet = await this.getWallet(orgName);
        let identity = await wallet.get(userId);

        if (!identity && userId === 'admin') {
            console.log(`Admin for ${orgName} not in wallet. Enrolling...`);
            await this.enrollAdminInWallet(orgName);
            identity = await wallet.get('admin');
        }

        if (!identity) {
            throw new Error(`Identite ${userId} non trouvee dans le wallet de ${orgName}`);
        }

        return identity;
    }

    async enrollAdminInWallet(orgName) {
        const caUrl = this.caConfigs[orgName];
        const wallet = await this.getWallet(orgName);

        const tlsCertPath = path.join(this.orgsRoot, 'fabric-ca', orgName, 'ca-cert.pem');
        const tlsCert = fs.readFileSync(tlsCertPath).toString();
        const caService = new FabricCAServices(caUrl, { trustedRoots: [tlsCert], verify: false }, `ca-${orgName}`);

        // Use bootstrap credentials from .env or default
        const enrollment = await caService.enroll({
            enrollmentID: 'admin',
            enrollmentSecret: process.env.CA_ADMIN_PASS || 'adminpw'
        });

        const mspId = `Org${orgName.charAt(0).toUpperCase() + orgName.slice(1)}MSP`;
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId,
            type: 'X.509',
        };

        await wallet.put('admin', x509Identity);
        console.log(`Admin for ${orgName} enrolled successfully.`);
    }

    async registerAndEnrollUser(orgName, userId, role = 'client') {
        const caUrl = this.caConfigs[orgName];
        const wallet = await this.getWallet(orgName);

        // 1. Check if user already exists
        if (await wallet.get(userId)) {
            throw new Error(`L'utilisateur ${userId} existe deja dans le wallet.`);
        }

        // 2. Setup CA client
        const tlsCertPath = path.join(this.orgsRoot, 'fabric-ca', orgName, 'ca-cert.pem');
        const tlsCert = fs.readFileSync(tlsCertPath).toString();
        const caService = new FabricCAServices(caUrl, { trustedRoots: [tlsCert], verify: false }, `ca-${orgName}`);

        // 3. Get registrar (admin)
        const adminIdentity = await this.getIdentity(orgName, 'admin');
        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
        const adminUser = await provider.getUserContext(adminIdentity, 'admin');

        // 4. Register
        const secret = await caService.register({
            enrollmentID: userId,
            enrollmentSecret: `${userId}pw`,
            role: role,
            maxEnrollments: -1
        }, adminUser);

        // 5. Enroll
        const enrollment = await caService.enroll({
            enrollmentID: userId,
            enrollmentSecret: secret
        });

        // 6. Save to wallet
        const mspId = `Org${orgName.charAt(0).toUpperCase() + orgName.slice(1)}MSP`;
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId,
            type: 'X.509',
        };

        await wallet.put(userId, x509Identity);
        return { success: true, userId, secret };
    }
}

module.exports = IdentityService;

