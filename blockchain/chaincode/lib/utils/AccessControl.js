'use strict';

/**
 * AccessControl utility to handle Identity and MSP based permissions.
 */
class AccessControl {
    static ROLES = {
        PRODUCTEUR: 'OrgProducteursMSP',
        EXPORTATEUR: 'OrgExportateursMSP',
        CERTIFICATEUR: 'OrgCertifMSP',
        MINISTERE: 'OrgMinistereMSP',
        TRANSFORMATEUR: 'OrgTransformateursMSP'
    };

    /**
     * Verify if the caller belongs to one of the allowed MSPs.
     * @param {Context} ctx 
     * @param {Array} allowedMSPs 
     */
    static checkRole(ctx, allowedMSPs) {
        const clientMSP = ctx.clientIdentity.getMSPID();
        if (!allowedMSPs.includes(clientMSP)) {
            throw new Error(`ACCES_REFUSE: L'organisation ${clientMSP} n'est pas autorisée à effectuer cette action.`);
        }
    }

    /**
     * Get the Client Identity (ID) from the certificate.
     * @param {Context} ctx 
     * @returns {string}
     */
    static getCallerId(ctx) {
        return ctx.clientIdentity.getID();
    }
}

module.exports = AccessControl;
