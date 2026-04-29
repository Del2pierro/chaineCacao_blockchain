'use strict';

/**
 * Definition of the official business models for ChainCacao.
 * These models MUST NOT be modified in terms of field names or types.
 */
class Schemas {
    static DOC_TYPES = {
        LOT: 'lot',
        TRANSFER: 'transfer',
        TRANSFORMATION: 'transformation',
        SHIPMENT: 'shipment',
        EVENT: 'event',
        CERTIFICATION: 'certification',
        ACTOR: 'actor'
    };

    static createLot(lotHash, farmerId, gps, poidsKg, espece, dateCollecte, mediaHash, coopId = null) {
        return {
            docType: Schemas.DOC_TYPES.LOT,
            lotHash,
            farmerId,
            gps, // { latitude, longitude }
            poidsKg,
            espece,
            dateCollecte,
            coopId,
            mediaHash,
            statut: 'COLLECTE'
        };
    }

    static createTransfer(transferHash, lotHashes, expediteurId, destinataireId, timestamp, preuveHash) {
        return {
            docType: Schemas.DOC_TYPES.TRANSFER,
            transferHash,
            lotHashes, // Array
            expediteurId,
            destinataireId,
            timestamp,
            preuveHash
        };
    }

    static createTransformation(transformationHash, lotHashes, typeProcessus, timestamp, preuveHash) {
        return {
            docType: Schemas.DOC_TYPES.TRANSFORMATION,
            transformationHash,
            lotHashes,
            typeProcessus,
            timestamp,
            preuveHash
        };
    }

    static createShipment(shipmentHash, lotHashes, exportateurId, destination, documentsHash, dateDepartPrevue, dateArriveePrevue) {
        return {
            docType: Schemas.DOC_TYPES.SHIPMENT,
            shipmentHash,
            lotHashes,
            exportateurId,
            destination,
            documentsHash,
            dateDepartPrevue,
            dateArriveePrevue
        };
    }

    static createTransportEvent(eventHash, refHash, transporteurIdHash, typeEvenement, gps, timestamp, preuveHash) {
        return {
            docType: Schemas.DOC_TYPES.EVENT,
            eventHash,
            referenceHash: refHash, // shipmentHash ou transferHash
            transporteurIdHash,
            typeEvenement,
            gps,
            timestamp,
            preuveHash
        };
    }

    static createCertification(certHash, refHash, verificateurId, statut, timestamp, rapportHash) {
        return {
            docType: Schemas.DOC_TYPES.CERTIFICATION,
            certHash,
            referenceHash: refHash, // lotHashes[] ou shipmentHash
            verificateurId,
            statut,
            timestamp,
            rapportHash
        };
    }

    static createActor(actorIdHash, typeActeur, clePublique, dateEnregistrement) {
        return {
            docType: Schemas.DOC_TYPES.ACTOR,
            actorIdHash,
            typeActeur,
            clePublique,
            dateEnregistrement,
            revoque: false
        };
    }
}

module.exports = Schemas;
