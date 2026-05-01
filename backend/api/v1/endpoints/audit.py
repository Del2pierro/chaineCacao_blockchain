from fastapi import APIRouter, Depends, HTTPException, status
from services.blockchain_gateway import BlockchainGateway

router = APIRouter()
gateway = BlockchainGateway()

@router.get("/history/{asset_hash}")
async def get_asset_history(asset_hash: str):
    """
    Fetch the complete immutable audit trail for any asset on the ledger.
    """
    return await gateway.get_history(asset_hash)

@router.get("/query/status/{status}")
async def query_by_status(status: str):
    """
    Search for lots based on their current status (utilizes CouchDB indexes).
    """
    return await gateway.query_lots_by_status(status)

@router.get("/query/farmer/{farmer_id}")
async def query_by_farmer(farmer_id: str):
    """
    Retrieve all lots associated with a specific farmer.
    """
    return await gateway.query_ledger("QueryLotsByFarmer", [farmer_id])

@router.get("/query/certifications/{ref_hash}")
async def get_certifications(ref_hash: str):
    """
    Get all certifications linked to a lot or a shipment.
    """
    return await gateway.query_ledger("QueryCertifications", [ref_hash])

@router.get("/eudr-report/{lot_hash}")
async def generate_eudr_report(lot_hash: str):
    """
    Generate a structured proof for EUDR compliance.
    Includes origin, history, and certifications.
    """
    result = await gateway.get_eudr_report(lot_hash)
    if not result.get("success"):
        raise HTTPException(status_code=404, detail=result.get("error"))
    return result

@router.get("/verify/{lot_hash}")
async def verify_lot_public(lot_hash: str):
    """
    Public endpoint for QR Code verification.
    Provides a simplified, consumer-friendly view of the lot's journey.
    """
    try:
        # 1. Get the latest state of the lot
        lot_details = await gateway.get_lot(lot_hash)
        
        # 2. Get the history of transfers
        history = await gateway.get_history(lot_hash)
        
        # 3. Format a consumer-friendly response
        return {
            "lot_id": lot_hash,
            "product": "Cacao du Togo",
            "harvest_info": {
                "date": lot_details.get("dateCollecte"),
                "species": lot_details.get("espece"),
                "weight": lot_details.get("poidsKg")
            },
            "origin_photo": f"/api/v1/lots/media/{lot_details.get('mediaHash')}" if lot_details.get("mediaHash") else None,
            "journey": [
                {
                    "step": h.get("value", {}).get("statut"),
                    "date": h.get("timestamp"),
                    "txId": h.get("txId")[:10] + "..." # Mask for consumers
                } for h in history
            ],
            "blockchain_verified": True
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail="Traceability info not found for this QR code")
