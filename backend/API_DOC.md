# 🚀 Documentation API Backend - ChainCacao

## 1. Vue d'ensemble
L'API FastAPI sert de pont entre les applications frontales et le réseau Hyperledger Fabric. Elle gère également le stockage des fichiers médias et les métadonnées dans PostgreSQL.

## 2. Technologies
*   **Framework** : FastAPI (Python)
*   **Base de données** : PostgreSQL (Métadonnées & Images)
*   **Blockchain Bridge** : Node.js Gateway via HTTP/JSON
*   **Stockage** : Système de fichiers local (`/uploads`)

## 3. Endpoints Principaux

### 🗳️ Gestion des Lots (`/api/v1/lots`)
*   `POST /` : **Création de Lot Unifiée**. Accepte un formulaire (multipart/form-data) avec les infos du lot + le fichier image.
    *   Génère le Hash SHA-256 de l'image.
    *   Stocke l'image et ses métadonnées (Postgres).
    *   Invoque le Smart Contract avec le hash de l'image.
*   `GET /{lot_hash}` : Récupère les détails complets (Blockchain).
*   `GET /media/{media_hash}` : Récupère le fichier image physique.

### 📜 Traçabilité & Audit (`/api/v1/audit`)
*   `GET /verify/{lot_hash}` : **Endpoint Public QR Code**. Retourne un résumé du voyage du lot.
*   `GET /history/{asset_hash}` : Retourne l'historique immuable complet.
*   `GET /eudr-report/{lot_hash}` : Génère un rapport de conformité technique pour l'UE.

## 4. Schéma PostgreSQL (`media_metadata`)
| Colonne | Type | Description |
| :--- | :--- | :--- |
| `lot_hash` | String | Lien avec le lot blockchain |
| `sha256_hash` | String | Hash unique du fichier (Clé unique) |
| `file_path` | String | Chemin sur le disque |
| `created_at` | DateTime | Date d'upload |

## 5. Intégration Gateway
L'API communique avec la Gateway Node.js en passant les headers `X-Org-Name` et `X-User-ID`. Cela permet au backend de signer des transactions au nom de différents acteurs.
