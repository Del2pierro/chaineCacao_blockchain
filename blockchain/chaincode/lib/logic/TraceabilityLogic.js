'use strict';

const Schemas = require('../models/Schemas');
const LedgerService = require('../services/LedgerService');

class TraceabilityLogic {
    constructor(ctx) {
        this.ctx = ctx;
        this.ledger = new LedgerService(ctx);
    }

    async createTransfer(transferHash, lotHashes, expediteurId, destinataireId, preuveHash) {
        // Validation existence
        for (const hash of lotHashes) {
            if (!(await this.ledger.exists(hash))) {
                throw new Error(`LOT_INEXISTANT: ${hash}`);
            }
        }

        const timestamp = new Date(this.ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        const transfer = Schemas.createTransfer(transferHash, lotHashes, expediteurId, destinataireId, timestamp, preuveHash);
        
        // Update lots
        for (const hash of lotHashes) {
            const lot = await this.ledger.getState(hash);
            lot.statut = `TRANSFERE_VERS_${destinataireId}`;
            lot.dernierTransfertHash = transferHash;
            await this.ledger.putState(hash, lot);
        }

        await this.ledger.putState(transferHash, transfer);
        return transfer;
    }

    async createTransformation(transformationHash, lotHashes, typeProcessus, preuveHash) {
        const timestamp = new Date(this.ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        const transformation = Schemas.createTransformation(transformationHash, lotHashes, typeProcessus, timestamp, preuveHash);
        
        for (const hash of lotHashes) {
            const lot = await this.ledger.getState(hash);
            if (lot) {
                lot.statut = `TRANSFORME_${typeProcessus}`;
                lot.transformationHash = transformationHash;
                await this.ledger.putState(hash, lot);
            }
        }

        await this.ledger.putState(transformationHash, transformation);
        return transformation;
    }

    async createShipment(shipmentHash, lotHashes, exportateurId, destination, documentsHash, dateDepart, dateArrivee) {
        const timestamp = new Date(this.ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        const shipment = Schemas.createShipment(shipmentHash, lotHashes, exportateurId, destination, documentsHash, dateDepart, dateArrivee, timestamp);
        
        for (const hash of lotHashes) {
            const lot = await this.ledger.getState(hash);
            if (lot) {
                lot.statut = `EXPEDIE_VERS_${destination}`;
                lot.shipmentHash = shipmentHash;
                await this.ledger.putState(hash, lot);
            }
        }

        await this.ledger.putState(shipmentHash, shipment);
        return shipment;
    }
}

module.exports = TraceabilityLogic;
