'use strict';

const { Contract } = require('fabric-contract-api');

class ChainCacaoContract extends Contract {

    async initLedger(ctx) {
        console.info('============= START : Initialize Ledger ===========');
        const lots = [
            {
                id: 'LOT001',
                productType: 'CACAO',
                weight: 500,
                origin: 'Kpalimé, Togo',
                producer: 'Coopérative AKAFO',
                owner: 'Coopérative AKAFO',
                status: 'CREATED',
                certifications: [],
                inspections: [],
                complianceEUDR: false,
                createdAt: new Date().toISOString()
            }
        ];

        for (let i = 0; i < lots.length; i++) {
            await ctx.stub.putState(lots[i].id, Buffer.from(JSON.stringify(lots[i])));
            console.info('Added <--> ', lots[i]);
        }
        console.info('============= END : Initialize Ledger ===========');
    }

    // --- ACCESS CONTROL UTILS ---
    async _checkRole(ctx, allowedMSPs) {
        const clientMSP = ctx.clientIdentity.getMSPID();
        if (!allowedMSPs.includes(clientMSP)) {
            throw new Error(`Access Denied: Organization ${clientMSP} is not authorized for this action.`);
        }
    }

    // --- BUSINESS FUNCTIONS ---

    /**
     * Create a new Lot
     * Only OrgProducteurs can create lots
     */
    async CreateLot(ctx, lotId, productType, weight, origin, producer) {
        await this._checkRole(ctx, ['OrgProducteursMSP']);

        const exists = await this._assetExists(ctx, lotId);
        if (exists) {
            throw new Error(`The lot ${lotId} already exists`);
        }

        const lot = {
            id: lotId,
            productType,
            weight: parseFloat(weight),
            origin,
            producer,
            owner: producer,
            status: 'CREATED',
            certifications: [],
            inspections: [],
            complianceEUDR: false,
            createdAt: new Date().toISOString(),
            docType: 'lot'
        };

        await ctx.stub.putState(lotId, Buffer.from(JSON.stringify(lot)));
        return JSON.stringify(lot);
    }

    /**
     * Add Certification to a Lot
     * Only OrgCertif can add certifications
     */
    async AddCertification(ctx, lotId, certName, certId, inspector) {
        await this._checkRole(ctx, ['OrgCertifMSP']);

        const lot = await this._getLot(ctx, lotId);
        
        const certification = {
            name: certName,
            id: certId,
            inspector,
            date: new Date().toISOString()
        };

        lot.certifications.push(certification);
        await ctx.stub.putState(lotId, Buffer.from(JSON.stringify(lot)));
        return JSON.stringify(lot);
    }

    /**
     * Transfer Ownership
     * Usually from Producer to Exporter or Exporter to Importer
     */
    async TransferLotOwnership(ctx, lotId, newOwner) {
        const lot = await this._getLot(ctx, lotId);
        
        // Validation: current owner must authorize or be the caller (simpler here for demo)
        // In real world, we check ctx.clientIdentity.getAttributeValue('name') or similar
        
        lot.owner = newOwner;
        await ctx.stub.putState(lotId, Buffer.from(JSON.stringify(lot)));
        return JSON.stringify(lot);
    }

    /**
     * Approve Lot for Export
     * Only Ministere or Certif can approve
     */
    async ApproveLot(ctx, lotId) {
        await this._checkRole(ctx, ['OrgCertifMSP', 'OrgMinistereMSP']);
        
        const lot = await this._getLot(ctx, lotId);
        lot.status = 'APPROVED';
        await ctx.stub.putState(lotId, Buffer.from(JSON.stringify(lot)));
        return JSON.stringify(lot);
    }

    /**
     * Verify EUDR Compliance
     * Logic based on certifications and origin
     */
    async VerifyComplianceEUDR(ctx, lotId) {
        const lot = await this._getLot(ctx, lotId);
        
        // Simple logic: must have at least one certification to be EUDR compliant for this demo
        if (lot.certifications.length > 0) {
            lot.complianceEUDR = true;
        } else {
            lot.complianceEUDR = false;
        }
        
        await ctx.stub.putState(lotId, Buffer.from(JSON.stringify(lot)));
        return JSON.stringify({ lotId, complianceEUDR: lot.complianceEUDR });
    }

    /**
     * Get Lot History
     */
    async GetLotHistory(ctx, lotId) {
        let resultsIterator = await ctx.stub.getHistoryForKey(lotId);
        let results = [];
        let res = await resultsIterator.next();
        while (!res.done) {
            if (res.value) {
                const obj = JSON.parse(res.value.value.toString('utf8'));
                results.push({
                    txId: res.value.txId,
                    timestamp: res.value.timestamp,
                    isDelete: res.value.isDelete,
                    data: obj
                });
            }
            res = await resultsIterator.next();
        }
        await resultsIterator.close();
        return JSON.stringify(results);
    }

    async GetLotById(ctx, lotId) {
        const lot = await this._getLot(ctx, lotId);
        return JSON.stringify(lot);
    }

    async GetAllLots(ctx) {
        const allResults = [];
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            allResults.push(record);
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }

    // --- PRIVATE UTILS ---
    async _getLot(ctx, lotId) {
        const lotJSON = await ctx.stub.getState(lotId);
        if (!lotJSON || lotJSON.length === 0) {
            throw new Error(`The lot ${lotId} does not exist`);
        }
        return JSON.parse(lotJSON.toString());
    }

    async _assetExists(ctx, lotId) {
        const lotJSON = await ctx.stub.getState(lotId);
        return lotJSON && lotJSON.length > 0;
    }
}

module.exports = ChainCacaoContract;
