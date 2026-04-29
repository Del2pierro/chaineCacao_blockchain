# Architecture Blockchain ChainCacao (Togo) - V2 Enterprise

Cette architecture a été conçue pour répondre aux exigences de production d'une supply chain agricole (Cacao/Café) hautement sécurisée et traçable.

## 1. Arborescence du Chaincode (Node.js)

Le code est structuré selon les principes de la **Clean Architecture** et de la modularité :

```text
blockchain/chaincode/
├── index.js                  # Point d'entrée du contrat
├── package.json              # Dépendances et scripts NPM
├── META-INF/                 # Configuration CouchDB (Indexation)
│   └── statedb/couchdb/indexes/
│       ├── indexDocType.json
│       ├── indexStatut.json
│       └── ...
└── lib/
    ├── chaincacao.js         # Façade du Smart Contract (Routing)
    ├── models/
    │   └── Schemas.js        # Définition stricte des modèles métier
    ├── services/
    │   └── LedgerService.js  # Abstraction des interactions World State
    └── utils/
        ├── AccessControl.js  # Gestion des rôles par MSP (Identity)
        └── Validation.js     # Validation stricte des données (Types, GPS, Hachages)
```

## 2. Modèles de Données (Asset-Based)

Tous les actifs partagent une structure JSON cohérente optimisée pour CouchDB :
- **LotOnChain** : L'unité de base (récolte).
- **TransfertOnChain** : Trace le changement de main entre acteurs.
- **TransformationOnChain** : Documente les processus industriels (séchage, torréfaction).
- **ExpeditionOnChain** : Gère l'exportation internationale.
- **EvenementTransportOnChain** : Télémétrie et logistique (GPS, Horodatage).
- **CertificationOnChain** : Preuves de conformité (EUDR, Bio, Fairtrade).

## 3. Sécurité et Contrôle d'Accès (RBAC)

L'accès aux fonctions est restreint par **MSPID** (Membership Service Provider) :
- `CreateLot` : Réservé à `OrgProducteursMSP`.
- `AddCertification` : Réservé à `OrgCertifMSP` et `OrgMinistereMSP`.
- `CreateShipment` : Réservé à `OrgExportateursMSP`.
- `RegisterActor` : Réservé à `OrgMinistereMSP` (Admin de confiance).

## 4. Optimisation Performance (CouchDB)

Des **Indexes Composites** ont été implémentés pour garantir des temps de réponse constants lors des requêtes complexes :
- Recherche par statut (`docType` + `statut`).
- Recherche par producteur (`docType` + `farmerId`).
- Recherche par destination d'export (`docType` + `destination`).

## 5. Commandes de Déploiement (Hyperledger Fabric)

Pour déployer cette nouvelle version sur un réseau existant :

1. **Packaging** :
   ```bash
   peer lifecycle chaincode package chaincacao.tar.gz --path ./blockchain/chaincode --lang node --label chaincacao_2.0
   ```

2. **Installation** (sur chaque peer) :
   ```bash
   peer lifecycle chaincode install chaincacao.tar.gz
   ```

3. **Approbation** (par chaque organisation) :
   ```bash
   peer lifecycle chaincode approveformyorg -o localhost:7050 --channelID chaincacaochannel --name chaincacao --version 2.0 --package-id <PACKAGE_ID> --sequence 2
   ```

4. **Commit** :
   ```bash
   peer lifecycle chaincode commit -o localhost:7050 --channelID chaincacaochannel --name chaincacao --version 2.0 --sequence 2
   ```

## 6. Conseils pour la Production

- **Utilisation de Private Data Collections** : Pour les prix d'achat ou données sensibles entre un producteur et un exportateur.
- **External Chaincode** : Déployer le chaincode en tant que service (Docker séparé) pour faciliter les mises à jour sans redémarrer les peers.
- **Fabric CA** : Utiliser des certificats d'identité spécifiques pour chaque utilisateur (Fermier, Agent) plutôt que des comptes Admin partagés.
- **Monitoring** : Surveiller les métriques via le endpoint Prometheus activé dans le `docker-compose`.
