# ⛓️ Documentation Blockchain - ChainCacao

## 1. Architecture du Réseau
Le réseau est basé sur Hyperledger Fabric v2.5 avec 4 organisations principales :
*   **Producteurs** : Enregistrent les récoltes (Lots).
*   **Exportateurs** : Gèrent les expéditions internationales.
*   **Certificateurs** : Valident la conformité (Bio, EUDR).
*   **Ministère** : Autorité de régulation et audit.

## 2. Smart Contract (Chaincode)
Le chaincode est écrit en Node.js et suit une architecture modulaire.

### Fonctions Principales :
*   `RegisterActor` : Enregistre un nouvel acteur avec son rôle.
*   `CreateLot` : Initialise un lot de cacao.
*   `CreateTransfer` : Enregistre le passage d'un lot d'un acteur à un autre.
*   `CreateShipment` : Crée une expédition pour l'exportation.
*   `GetHistoryForAsset` : Retourne la piste d'audit immuable.

## 3. Confidentialité (Private Data Collections)
Certaines données sensibles sont stockées dans la collection privée `collectionPrivateLots` :
*   **Données Privées** : Coordonnées GPS, ID Fermier.
*   **Visibilité** : Uniquement accessible par `OrgProducteurs`, `OrgExportateurs` et `OrgMinistere`.
*   **Preuve** : Un hash de ces données est stocké sur le ledger public pour garantir l'intégrité sans révéler l'info.

## 4. Contrôle d'Accès (RBAC)
Le contrat vérifie le rôle dans le certificat de l'appelant (MSP ID) :
*   `PRODUCTEUR` : Peut créer des lots et initier des transferts.
*   `EXPORTATEUR` : Peut créer des expéditions et voir les données privées EUDR.
*   `MINISTERE` : Accès complet en lecture pour audit.
