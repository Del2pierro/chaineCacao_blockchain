'use strict';

const Schemas = require('../models/Schemas');
const LedgerService = require('../services/LedgerService');
const Validation = require('../utils/Validation');

class LotLogic {
    constructor(ctx) {
        this.ctx = ctx;
        this.ledger = new LedgerService(ctx);
    }

    async createLot(lotHash, farmerId, gpsStr, poidsKg, espece, dateCollecte, mediaHash, coopId) {
        const gps = JSON.parse(gpsStr);
        Validation.checkGPS(gps);
        Validation.checkNumber(parseFloat(poidsKg), 'poidsKg');
        Validation.checkTimestamp(dateCollecte, 'dateCollecte');

        if (await this.ledger.exists(lotHash)) {
            throw new Error(`LOT_EXISTE: Le lot ${lotHash} existe déjà.`);
        }

        // 1. Données Publiques (visibles par tous)
        const publicLot = {
            docType: 'lot',
            lotHash: lotHash,
            espece: espece,
            poidsKg: parseFloat(poidsKg),
            dateCollecte: dateCollecte,
            statut: 'COLLECTE',
            coopId: coopId
        };
        await this.ledger.putState(lotHash, publicLot);

        // 2. Données Privées (GPS, Farmer ID, etc.)
        const privateDetails = {
            lotHash: lotHash,
            farmerId: farmerId,
            gps: gps,
            mediaHash: mediaHash
        };
        
        // Utilisation de la collection privée
        await this.ctx.stub.putPrivateData('collectionPrivateLots', lotHash, Buffer.from(JSON.stringify(privateDetails)));

        return publicLot;
    }

    async getLot(lotHash) {
        const publicLot = await this.ledger.getState(lotHash);
        if (!publicLot) throw new Error(`LOT_NON_TROUVE: ${lotHash}`);

        // Tenter de récupérer les données privées
        try {
            const privateDataBuffer = await this.ctx.stub.getPrivateData('collectionPrivateLots', lotHash);
            if (privateDataBuffer && privateDataBuffer.length > 0) {
                const privateDetails = JSON.parse(privateDataBuffer.toString());
                return { ...publicLot, ...privateDetails };
            }
        } catch (e) {
            // Si l'organisation n'a pas accès, on ne renvoie que le public
            console.log(`Accès privé refusé pour ${lotHash}`);
        }

        return publicLot;
    }


    async updateStatus(lotHash, nouveauStatut) {
        const lot = await this.getLot(lotHash);
        lot.statut = nouveauStatut;
        await this.ledger.putState(lotHash, lot);
        return lot;
    }
}

module.exports = LotLogic;
