'use strict';

/**
 * Strict Validation utility for business models.
 */
class Validation {
    /**
     * Generic required field check.
     */
    static checkRequired(obj, fields) {
        for (const field of fields) {
            if (obj[field] === undefined || obj[field] === null || obj[field] === '') {
                throw new Error(`VALIDATION_ERREUR: Le champ [${field}] est obligatoire.`);
            }
        }
    }

    /**
     * Check if value is a valid number.
     */
    static checkNumber(value, fieldName) {
        if (typeof value !== 'number' || isNaN(value)) {
            throw new Error(`VALIDATION_ERREUR: Le champ [${fieldName}] doit être un nombre.`);
        }
    }

    /**
     * Check if value is a valid timestamp (ISO String or Number).
     */
    static checkTimestamp(value, fieldName) {
        if (!value || isNaN(Date.parse(value))) {
            throw new Error(`VALIDATION_ERREUR: Le champ [${fieldName}] doit être un timestamp valide.`);
        }
    }

    /**
     * Check GPS object structure.
     */
    static checkGPS(gps) {
        if (!gps || typeof gps.latitude !== 'number' || typeof gps.longitude !== 'number') {
            throw new Error(`VALIDATION_ERREUR: Le champ [gps] doit contenir latitude et longitude (nombres).`);
        }
    }

    /**
     * Check if string matches a hash format (simple check for non-empty string here, can be hex regex).
     */
    static checkHash(hash, fieldName) {
        if (typeof hash !== 'string' || hash.length < 8) {
            throw new Error(`VALIDATION_ERREUR: Le champ [${fieldName}] n'est pas un hash valide.`);
        }
    }
}

module.exports = Validation;
