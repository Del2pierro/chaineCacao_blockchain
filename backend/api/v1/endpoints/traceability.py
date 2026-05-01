from fastapi import APIRouter, Depends, HTTPException, status
from models.schemas import TransferCreate, TransformationCreate, ShipmentCreate
from services.blockchain_gateway import BlockchainGateway

router = APIRouter()
gateway = BlockchainGateway()

@router.post("/transfers", status_code=status.HTTP_201_CREATED)
async def create_transfer(transfer: TransferCreate):
    """
    Record a ownership transfer between two actors.
    """
    try:
        msp_id = "OrgProducteursMSP"
        return await gateway.create_transfer(transfer.model_dump(), msp_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/transformations", status_code=status.HTTP_201_CREATED)
async def create_transformation(transformation: TransformationCreate):
    """
    Record an industrial transformation process.
    """
    try:
        msp_id = "OrgExportateursMSP"
        args = [
            transformation.transformation_hash, 
            str(transformation.lot_hashes), 
            transformation.type_processus, 
            transformation.preuve_hash
        ]
        return await gateway.invoke_transaction("CreateTransformation", args, msp_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/shipments", status_code=status.HTTP_201_CREATED)
async def create_shipment(shipment: ShipmentCreate):
    """
    Register a new international shipment.
    Role: EXPORTATEUR
    """
    try:
        msp_id = "OrgExportateursMSP"
        data = shipment.model_dump()
        args = [
            data['shipmentHash'], str(data['lotHashes']), data['exportateurId'],
            data['destination'], data['documentsHash'], data['dateDepartPrevue'],
            data['dateArriveePrevue']
        ]
        return await gateway.invoke_transaction("CreateShipment", args, msp_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
