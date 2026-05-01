'use strict';

const { Contract } = require('fabric-contract-api');
const AccessControl = require('./utils/AccessControl');
const LedgerService = require('./services/LedgerService');
const ActorLogic = require('./logic/ActorLogic');
const LotLogic = require('./logic/LotLogic');
const TraceabilityLogic = require('./logic/TraceabilityLogic');
const AuditLogic = require('./logic/AuditLogic');

class ChainCacaoContract extends Contract {

    async initLedger(ctx) {
        console.info('============= START : Initialize Ledger ===========');
    }

    // =========================================================================
    // ACTEURS
    // =========================================================================

    async RegisterActor(ctx, actorIdHash, typeActeur, clePublique) {
        AccessControl.checkRole(ctx, [AccessControl.ROLES.MINISTERE]);
        const logic = new ActorLogic(ctx);
        const result = await logic.registerActor(actorIdHash, typeActeur, clePublique);
        return JSON.stringify(result);
    }

    async GetActor(ctx, actorIdHash) {
        const logic = new ActorLogic(ctx);
        const result = await logic.getActor(actorIdHash);
        return JSON.stringify(result);
    }

    // =========================================================================
    // LOTS
    // =========================================================================

    async CreateLot(ctx, lotHash, farmerId, gpsStr, poidsKg, espece, dateCollecte, mediaHash, coopId) {
        AccessControl.checkRole(ctx, [AccessControl.ROLES.PRODUCTEUR, AccessControl.ROLES.CERTIFICATEUR]);
        const logic = new LotLogic(ctx);
        const result = await logic.createLot(lotHash, farmerId, gpsStr, poidsKg, espece, dateCollecte, mediaHash, coopId);
        return JSON.stringify(result);
    }

    async GetLot(ctx, lotHash) {
        const logic = new LotLogic(ctx);
        const result = await logic.getLot(lotHash);
        return JSON.stringify(result);
    }

    async UpdateLotStatus(ctx, lotHash, nouveauStatut) {
        AccessControl.checkRole(ctx, [AccessControl.ROLES.PRODUCTEUR, AccessControl.ROLES.CERTIFICATEUR, AccessControl.ROLES.EXPORTATEUR]);
        const logic = new LotLogic(ctx);
        const result = await logic.updateStatus(lotHash, nouveauStatut);
        return JSON.stringify(result);
    }

    // =========================================================================
    // TRANSFERTS / TRANSFORMATIONS / EXPEDITIONS
    // =========================================================================

    async CreateTransfer(ctx, transferHash, lotHashesStr, expediteurId, destinataireId, preuveHash) {
        const logic = new TraceabilityLogic(ctx);
        const result = await logic.createTransfer(transferHash, JSON.parse(lotHashesStr), expediteurId, destinataireId, preuveHash);
        return JSON.stringify(result);
    }

    async CreateTransformation(ctx, transformationHash, lotHashesStr, typeProcessus, preuveHash) {
        const logic = new TraceabilityLogic(ctx);
        const result = await logic.createTransformation(transformationHash, JSON.parse(lotHashesStr), typeProcessus, preuveHash);
        return JSON.stringify(result);
    }

    async CreateShipment(ctx, shipmentHash, lotHashesStr, exportateurId, destination, documentsHash, dateDepart, dateArrivee) {
        AccessControl.checkRole(ctx, [AccessControl.ROLES.EXPORTATEUR]);
        const logic = new TraceabilityLogic(ctx);
        const result = await logic.createShipment(shipmentHash, JSON.parse(lotHashesStr), exportateurId, destination, documentsHash, dateDepart, dateArrivee);
        return JSON.stringify(result);
    }

    // =========================================================================
    // REQUETES AVANCEES / AUDIT
    // =========================================================================

    async GetHistoryForAsset(ctx, assetHash) {
        const logic = new AuditLogic(ctx);
        const result = await logic.getHistory(assetHash);
        return JSON.stringify(result);
    }

    async QueryLotsByStatus(ctx, statut) {
        const logic = new AuditLogic(ctx);
        const result = await logic.queryLotsByStatus(statut);
        return JSON.stringify(result);
    }

    async QueryCertifications(ctx, refHash) {
        const logic = new AuditLogic(ctx);
        const result = await logic.queryCertifications(refHash);
        return JSON.stringify(result);
    }
}

module.exports = ChainCacaoContract;
