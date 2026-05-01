from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
import hashlib
import shutil
import os
import json
from typing import Dict, List, Optional
from models.schemas import LotCreate, LotResponse
from services.blockchain_gateway import BlockchainGateway
from database import get_db, MediaMetadata

router = APIRouter()
gateway = BlockchainGateway()
UPLOAD_DIR = "uploads"

# --- Unified Endpoint: Creation + Upload ---

@router.post("/", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_new_lot(
    lot_hash: str = Form(...),
    farmer_id: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    poids_kg: float = Form(...),
    espece: str = Form(...),
    date_collecte: str = Form(...),
    coop_id: str = Form(""),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Unified endpoint: Upload image, generate hash, store in Postgres, and create Lot on Blockchain.
    """
    try:
        # 1. Process Image and Generate Hash
        content = await file.read()
        sha256_hash = hashlib.sha256(content).hexdigest()
        
        file_ext = os.path.splitext(file.filename)[1]
        filename = f"{sha256_hash}{file_ext}"
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        # Create upload dir if not exists
        if not os.path.exists(UPLOAD_DIR):
            os.makedirs(UPLOAD_DIR)

        if not os.path.exists(file_path):
            with open(file_path, "wb") as buffer:
                buffer.write(content)

        # 2. Store metadata in PostgreSQL
        db_media = MediaMetadata(
            lot_hash=lot_hash,
            filename=file.filename,
            file_path=file_path,
            sha256_hash=sha256_hash
        )
        db.add(db_media)
        db.commit()

        # 3. Prepare data for Blockchain
        lot_data = {
            "lot_hash": lot_hash,
            "farmer_id": farmer_id,
            "gps": {"latitude": latitude, "longitude": longitude},
            "poids_kg": poids_kg,
            "espece": espece,
            "date_collecte": date_collecte,
            "media_hash": sha256_hash,
            "coop_id": coop_id
        }

        # 4. Invoke Blockchain
        # Note: Identity (producteurs/Admin) can be dynamically set via JWT in production
        blockchain_result = await gateway.create_lot(lot_data, "producteurs", "Admin")
        
        return {
            "success": True,
            "blockchain": blockchain_result,
            "media": {
                "hash": sha256_hash,
                "url": f"/api/v1/lots/media/{sha256_hash}"
            }
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

# --- Helper Endpoints ---

@router.get("/media/{media_hash}")
async def get_media(media_hash: str, db: Session = Depends(get_db)):
    """
    Retrieve an image from the filesystem via its SHA-256 hash.
    """
    db_media = db.query(MediaMetadata).filter(MediaMetadata.sha256_hash == media_hash).first()
    if not db_media or not os.path.exists(db_media.file_path):
        raise HTTPException(status_code=404, detail="Media not found")
    
    return FileResponse(db_media.file_path)

@router.get("/{lot_hash}", response_model=dict)
async def get_lot_details(lot_hash: str):
    """
    Retrieve full details of a specific lot from the ledger.
    """
    result = await gateway.get_lot(lot_hash)
    if not result:
        raise HTTPException(status_code=404, detail="Lot not found")
    return result

@router.patch("/{lot_hash}/status")
async def update_lot_status(lot_hash: str, new_status: str):
    """
    Update the status of a lot (e.g., COLLECTE -> EN_TRANSIT).
    """
    try:
        result = await gateway.invoke_transaction("UpdateLotStatus", [lot_hash, new_status], "producteurs", "Admin")
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
