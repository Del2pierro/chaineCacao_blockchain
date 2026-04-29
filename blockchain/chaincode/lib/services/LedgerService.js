'use strict';

/**
 * LedgerService handles all direct interactions with the world state (Stub).
 */
class LedgerService {
    constructor(ctx) {
        this.ctx = ctx;
    }

    /**
     * Put state to ledger.
     */
    async putState(id, data) {
        await this.ctx.stub.putState(id, Buffer.from(JSON.stringify(data)));
    }

    /**
     * Get state from ledger.
     */
    async getState(id) {
        const dataJSON = await this.ctx.stub.getState(id);
        if (!dataJSON || dataJSON.length === 0) {
            return null;
        }
        return JSON.parse(dataJSON.toString());
    }

    /**
     * Check if asset exists.
     */
    async exists(id) {
        const data = await this.ctx.stub.getState(id);
        return data && data.length > 0;
    }

    /**
     * Execute a Rich Query (CouchDB).
     */
    async getQueryResultForQueryString(queryString) {
        const resultsIterator = await this.ctx.stub.getQueryResult(queryString);
        const results = [];
        let res = await resultsIterator.next();
        while (!res.done) {
            if (res.value && res.value.value) {
                const strValue = Buffer.from(res.value.value.toString()).toString('utf8');
                let record;
                try {
                    record = JSON.parse(strValue);
                } catch (err) {
                    record = strValue;
                }
                results.push(record);
            }
            res = await resultsIterator.next();
        }
        await resultsIterator.close();
        return results;
    }

    /**
     * Get History for an asset.
     */
    async getHistory(id) {
        const resultsIterator = await this.ctx.stub.getHistoryForKey(id);
        const results = [];
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
        return results;
    }
}

module.exports = LedgerService;
