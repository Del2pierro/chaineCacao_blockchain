'use strict';

const Schemas = require('../models/Schemas');
const LedgerService = require('../services/LedgerService');

class ActorLogic {
    constructor(ctx) {
        this.ctx = ctx;
        this.ledger = new LedgerService(ctx);
    }

    async registerActor(actorIdHash, typeActeur, clePublique) {
        if (await this.ledger.exists(actorIdHash)) {
            throw new Error(`ACTEUR_EXISTE: L'acteur ${actorIdHash} est deja enregistre.`);
        }

        const timestamp = new Date(this.ctx.stub.getTxTimestamp().seconds.low * 1000).toISOString();
        const actor = Schemas.createActor(actorIdHash, typeActeur, clePublique, timestamp);
        
        await this.ledger.putState(actorIdHash, actor);
        return actor;
    }

    async getActor(actorIdHash) {
        const actor = await this.ledger.getState(actorIdHash);
        if (!actor) throw new Error(`ACTEUR_NON_TROUVE: ${actorIdHash}`);
        return actor;
    }
}

module.exports = ActorLogic;
