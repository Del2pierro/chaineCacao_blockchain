'use strict';

const { Contract } = require('fabric-contract-api');
const AccessControl = require('./utils/AccessControl');
const Validation = require('./utils/Validation');
const Schemas = require('./models/Schemas');
const LedgerService = require('./services/LedgerService');

class ChainCacaoContract extends Contract {

    async initLedger(ctx) {
        console.info('============= START : Initialize Ledger ===========');
        // Initialisation optionnelle ou vide pour production
        console.info('============= END : Initialize Ledger ===========');
    }

    // =========================================================================
    // ACTEURS
    // =========================================================================

    async RegisterActor(ctx, actorIdHash, typeActeur, clePublique) {
        // Seul le Ministère ou l'admin peut enregistrer des acteurs officiels
        AccessControl.checkRole(ctx, [AccessControl.ROLES.MINISTERE]);
        
        const ledger = new LedgerService(ctx);
        if (await ledger.exists(actorIdHash)) {
            throw new Error(`ACTEUR_EXISTE: L'acteur ${actorIdHash} est déjà enregistré.`);
        }

        const timestamp = ctx.stub.getTxTimestamp().seconds.low;
        const dateStr = new Date(timestamp * 1000).toISOString();

        const actor = Schemas.createActor(actorIdHash, typeActeur, clePublique, dateStr);
        await ledger.putState(actorIdHash, actor);
        
        return JSON.stringify(actor);
    }

    // =========================================================================
    // LOTS
    // =========================================================================

    async CreateLot(ctx, lotHash, farmerId, gpsStr, poidsKg, espece, dateCollecte, mediaHash, coopId) {
        AccessControl.checkRole(ctx, [AccessControl.ROLES.PRODUCTEUR, AccessControl.ROLES.CERTIFICATEUR]);
        
        const gps = JSON.parse(gpsStr);
        Validation.checkGPS(gps);
        Validation.checkNumber(parseFloat(poidsKg), 'poidsKg');
        Validation.checkTimestamp(dateCollecte, 'dateCollecte');

        const ledger = new LedgerService(ctx);
        if (await ledger.exists(lotHash)) {
            throw new Error(`LOT_EXISTE: Le lot ${lotHash} existe déjà.`);
        }

        const lot = Schemas.createLot(lotHash, farmerId, gps, parseFloat(poidsKg), espece, dateCollecte, mediaHash, coopId);
        await ledger.putState(lotHash, lot);
        
        return JSON.stringify(lot);
    }

    async GetLot(ctx, lotHash) {
        const ledger = new LedgerService(ctx);
        const lot = await ledger.getState(lotHash);
        if (!lot) throw new Error(`LOT_NON_TROUVE: ${lotHash}`);
        return JSON.stringify(lot);
    }

    async GetAllLots(ctx) {
        const ledger = new LedgerService(ctx);
        const query = { selector: { docType: Schemas.DOC_TYPES.LOT } };
        const results = await ledger.getQueryResultForQueryString(JSON.stringify(query));
        return JSON.stringify(results);
    }

    async UpdateLotStatus(ctx, lotHash, nouveauStatut) {
        // Autorisé pour Producteurs (collecte), Certif (qualité), Exportateurs (reçu)
        AccessControl.checkRole(ctx, [AccessControl.ROLES.PRODUCTEUR, AccessControl.ROLES.CERTIFICATEUR, AccessControl.ROLES.EXPORTATEUR]);
        
        const ledger = new LedgerService(ctx);
        const lot = await ledger.getState(lotHash);
        if (!lot) throw new Error(`LOT_NON_TROUVE: ${lotHash}`);

        lot.statut = nouveauStatut;
        await ledger.putState(lotHash, lot);
        return JSON.stringify(lot);
    }

    // =========================================================================
    // TRANSFERTS
    // =========================================================================

    async CreateTransfer(ctx, transferHash, lotHashesStr, expediteurId, destinataireId, preuveHash) {
        const lotHashes = JSON.parse(lotHashesStr);
        const ledger = new LedgerService(ctx);

        // Vérifier existence des lots
        for (const hash of lotHashes) {
            if (!(await ledger.exists(hash))) throw new Error(`LOT_INEXISTANT: ${hash}`);
        }

        const timestamp = new Date(ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        const transfer = Schemas.createTransfer(transferHash, lotHashes, expediteurId, destinataireId, timestamp, preuveHash);
        
        await ledger.putState(transferHash, transfer);
        return JSON.stringify(transfer);
    }

    async GetTransfer(ctx, transferHash) {
        const ledger = new LedgerService(ctx);
        const transfer = await ledger.getState(transferHash);
        if (!transfer) throw new Error(`TRANSFERT_NON_TROUVE: ${transferHash}`);
        return JSON.stringify(transfer);
    }

    // =========================================================================
    // TRANSFORMATIONS
    // =========================================================================

    async CreateTransformation(ctx, transformationHash, lotHashesStr, typeProcessus, preuveHash) {
        const lotHashes = JSON.parse(lotHashesStr);
        const ledger = new LedgerService(ctx);

        const timestamp = new Date(ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        const transformation = Schemas.createTransformation(transformationHash, lotHashes, typeProcessus, timestamp, preuveHash);
        
        await ledger.putState(transformationHash, transformation);
        return JSON.stringify(transformation);
    }

    async GetTransformation(ctx, transformationHash) {
        const ledger = new LedgerService(ctx);
        const trans = await ledger.getState(transformationHash);
        if (!trans) throw new Error(`TRANSFORMATION_NON_TROUVE: ${transformationHash}`);
        return JSON.stringify(trans);
    }

    // =========================================================================
    // EXPEDITIONS (SHIPMENTS)
    // =========================================================================

    async CreateShipment(ctx, shipmentHash, lotHashesStr, exportateurId, destination, documentsHash, dateDepart, dateArrivee) {
        AccessControl.checkRole(ctx, [AccessControl.ROLES.EXPORTATEUR]);
        
        const lotHashes = JSON.parse(lotHashesStr);
        const ledger = new LedgerService(ctx);

        const shipment = Schemas.createShipment(shipmentHash, lotHashes, exportateurId, destination, documentsHash, dateDepart, dateArrivee);
        await ledger.putState(shipmentHash, shipment);
        
        return JSON.stringify(shipment);
    }

    async GetShipment(ctx, shipmentHash) {
        const ledger = new LedgerService(ctx);
        const shipment = await ledger.getState(shipmentHash);
        if (!shipment) throw new Error(`SHIPMENT_NON_TROUVE: ${shipmentHash}`);
        return JSON.stringify(shipment);
    }

    // =========================================================================
    // EVENEMENTS TRANSPORT
    // =========================================================================

    async AddTransportEvent(ctx, eventHash, refHash, transporteurIdHash, typeEvenement, gpsStr, preuveHash) {
        const gps = JSON.parse(gpsStr);
        const timestamp = new Date(ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        
        const event = Schemas.createTransportEvent(eventHash, refHash, transporteurIdHash, typeEvenement, gps, timestamp, preuveHash);
        const ledger = new LedgerService(ctx);
        await ledger.putState(eventHash, event);
        
        return JSON.stringify(event);
    }

    async GetTransportEvents(ctx, refHash) {
        const ledger = new LedgerService(ctx);
        const query = { 
            selector: { 
                docType: Schemas.DOC_TYPES.EVENT,
                referenceHash: refHash
            } 
        };
        const results = await ledger.getQueryResultForQueryString(JSON.stringify(query));
        return JSON.stringify(results);
    }

    // =========================================================================
    // CERTIFICATIONS
    // =========================================================================

    async AddCertification(ctx, certHash, refHash, verificateurId, statut, rapportHash) {
        AccessControl.checkRole(ctx, [AccessControl.ROLES.CERTIFICATEUR, AccessControl.ROLES.MINISTERE]);
        
        const timestamp = new Date(ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        const cert = Schemas.createCertification(certHash, refHash, verificateurId, statut, timestamp, rapportHash);
        
        const ledger = new LedgerService(ctx);
        await ledger.putState(certHash, cert);
        
        return JSON.stringify(cert);
    }

    async GetCertification(ctx, certHash) {
        const ledger = new LedgerService(ctx);
        const cert = await ledger.getState(certHash);
        if (!cert) throw new Error(`CERTIFICATION_NON_TROUVE: ${certHash}`);
        return JSON.stringify(cert);
    }

    // =========================================================================
    // REQUETES AVANCEES ET HISTORIQUE
    // =========================================================================

    async GetHistoryForAsset(ctx, assetHash) {
        const ledger = new LedgerService(ctx);
        const history = await ledger.getHistory(assetHash);
        return JSON.stringify(history);
    }

    async QueryLotsByStatus(ctx, statut) {
        const ledger = new LedgerService(ctx);
        const query = { selector: { docType: Schemas.DOC_TYPES.LOT, statut: statut } };
        const results = await ledger.getQueryResultForQueryString(JSON.stringify(query));
        return JSON.stringify(results);
    }

    async QueryLotsByFarmer(ctx, farmerId) {
        const ledger = new LedgerService(ctx);
        const query = { selector: { docType: Schemas.DOC_TYPES.LOT, farmerId: farmerId } };
        const results = await ledger.getQueryResultForQueryString(JSON.stringify(query));
        return JSON.stringify(results);
    }

    async QueryShipmentsByDestination(ctx, destination) {
        const ledger = new LedgerService(ctx);
        const query = { selector: { docType: Schemas.DOC_TYPES.SHIPMENT, destination: destination } };
        const results = await ledger.getQueryResultForQueryString(JSON.stringify(query));
        return JSON.stringify(results);
    }

    async QueryCertifications(ctx, refHash) {
        const ledger = new LedgerService(ctx);
        const query = { 
            selector: { 
                docType: Schemas.DOC_TYPES.CERTIFICATION,
                referenceHash: refHash
            } 
        };
        const results = await ledger.getQueryResultForQueryString(JSON.stringify(query));
        return JSON.stringify(results);
    }
}

module.exports = ChainCacaoContract;
