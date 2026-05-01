const FabricCAServices = require('fabric-ca-client');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

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

    async getIdentity(orgName, userId = 'Admin') {
        const orgDomain = `${orgName}.chaincacao.com`;
        const userPath = path.join(this.orgsRoot, 'peerOrganizations', orgDomain, 'users', `${userId}@${orgDomain}`);
        
        const mspDir = path.join(userPath, 'msp');
        const certPath = path.join(mspDir, 'signcerts', `cert.pem`); // Normalized path for CA-enrolled users
        const keyDir = path.join(mspDir, 'keystore');
        
        // Try fallback to cryptogen path if CA path doesn't exist
        let finalCertPath = certPath;
        if (!fs.existsSync(certPath)) {
            finalCertPath = path.join(userPath, 'msp', 'signcerts', `${userId}@${orgDomain}-cert.pem`);
        }

        if (!fs.existsSync(finalCertPath)) {
            throw new Error(`Identité non trouvée pour ${userId} dans ${orgName}`);
        }

        const credentials = fs.readFileSync(finalCertPath);
        const keyFiles = fs.readdirSync(keyDir);
        const privateKey = fs.readFileSync(path.join(keyDir, keyFiles[0]));

        const mspId = `${orgName.charAt(0).toUpperCase() + orgName.slice(1)}MSP`;

        return { mspId, credentials, privateKey };
    }

    async registerAndEnrollUser(orgName, userId, role = 'client') {
        const caUrl = this.caConfigs[orgName];
        if (!caUrl) throw new Error(`Configuration CA manquante pour ${orgName}`);

        const orgDomain = `${orgName}.chaincacao.com`;
        const tlsCertPath = path.join(this.orgsRoot, 'fabric-ca', orgName, 'ca-cert.pem');
        const tlsCert = fs.readFileSync(tlsCertPath).toString();


        const caService = new FabricCAServices(caUrl, { trustedRoots: [tlsCert], verify: false }, `ca-${orgName}`);

        // 1. Enroll the registrar (Admin) to perform the registration
        const adminIdentity = await this.getIdentity(orgName, 'Admin');
        const registrar = await caService.newIdentityService().getIdentity('admin', adminIdentity); // In real prod, use proper registrar

        // 2. Register the user
        const secret = await caService.register({
            enrollmentID: userId,
            enrollmentSecret: `${userId}pw`,
            role: role,
            affiliation: `${orgName}.department1`,
            maxEnrollments: -1
        }, {
            getIdentity: () => ({
                getEnrollmentID: () => 'admin',
                getSigningIdentity: () => ({
                    sign: (msg) => {
                        const sign = crypto.createSign('sha256');
                        sign.update(msg);
                        return sign.sign(adminIdentity.privateKey);
                    },
                    getPublicContext: () => ({ getCertificate: () => adminIdentity.credentials.toString() })
                })
            })
        });

        // 3. Enroll the user
        const enrollment = await caService.enroll({
            enrollmentID: userId,
            enrollmentSecret: secret
        });

        // 4. Save to filesystem (so gateway can find it)
        const userPath = path.join(this.orgsRoot, 'peerOrganizations', orgDomain, 'users', `${userId}@${orgDomain}`, 'msp');
        fs.mkdirSync(path.join(userPath, 'signcerts'), { recursive: true });
        fs.mkdirSync(path.join(userPath, 'keystore'), { recursive: true });

        fs.writeFileSync(path.join(userPath, 'signcerts', 'cert.pem'), enrollment.certificate);
        fs.writeFileSync(path.join(userPath, 'keystore', 'priv_sk'), enrollment.key.toBytes());

        return { success: true, userId, secret };
    }
}

module.exports = IdentityService;

