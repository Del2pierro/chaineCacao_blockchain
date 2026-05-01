from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict
from datetime import datetime

class GPSModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    latitude: float
    longitude: float

class LotCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    lot_hash: str = Field(alias="lotHash")
    farmer_id: str = Field(alias="farmerId")
    gps: GPSModel
    poids_kg: float = Field(alias="poidsKg")
    espece: str
    date_collecte: str = Field(alias="dateCollecte")
    media_hash: str = Field(alias="mediaHash")
    coop_id: Optional[str] = Field(None, alias="coopId")

class LotResponse(LotCreate):
    statut: str

class TransferCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    transfer_hash: str = Field(alias="transferHash")
    lot_hashes: List[str] = Field(alias="lotHashes")
    expediteur_id: str = Field(alias="expediteurId")
    destinataire_id: str = Field(alias="destinataireId")
    preuve_hash: str = Field(alias="preuveHash")

class TransformationCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    transformation_hash: str = Field(alias="transformationHash")
    lot_hashes: List[str] = Field(alias="lotHashes")
    type_processus: str = Field(alias="typeProcessus")
    preuve_hash: str = Field(alias="preuveHash")

class ShipmentCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    shipment_hash: str = Field(alias="shipmentHash")
    lot_hashes: List[str] = Field(alias="lotHashes")
    exportateur_id: str = Field(alias="exportateurId")
    destination: str
    documents_hash: str = Field(alias="documentsHash")
    date_depart_prevue: str = Field(alias="dateDepartPrevue")
    date_arrivee_prevue: str = Field(alias="dateArriveePrevue")

class TransportEventCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    event_hash: str = Field(alias="eventHash")
    ref_hash: str = Field(alias="refHash")
    transporteur_id_hash: str = Field(alias="transporteurIdHash")
    type_evenement: str = Field(alias="typeEvenement")
    gps: GPSModel
    preuve_hash: str = Field(alias="preuveHash")

class CertificationCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    cert_hash: str = Field(alias="certHash")
    ref_hash: str = Field(alias="refHash")
    verificateur_id: str = Field(alias="verificateurId")
    statut: str
    rapport_hash: str = Field(alias="rapportHash")

class ActorRegister(BaseModel):
    model_config = ConfigDict(populate_by_name=True)
    actor_id_hash: str = Field(alias="actorIdHash")
    type_acteur: str = Field(alias="typeActeur")
    cle_publique: str = Field(alias="clePublique")
    org_name: str = Field(alias="orgName")


class ActorResponse(ActorRegister):
    date_enregistrement: str = Field(alias="dateEnregistrement")
    revoque: bool
