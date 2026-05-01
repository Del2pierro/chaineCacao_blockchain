import json
import logging
import httpx
import os
from typing import Any, Dict, List, Optional
from dotenv import load_dotenv

load_dotenv()

class BlockchainGateway:
    def __init__(self):
        self.logger = logging.getLogger("blockchain_gateway")
        # URL of our Node.js bridge from .env
        self.gateway_url = os.getenv("BLOCKCHAIN_GATEWAY_URL", "http://localhost:3000")
        self.channel_name = os.getenv("CHANNEL_NAME", "chaincacaochannel")
        self.chaincode_name = os.getenv("CHAINCODE_NAME", "chaincacao")


    async def invoke_transaction(self, function_name: str, args: List[str], org_name: str = "producteurs", user_id: str = "Admin") -> Dict[str, Any]:
        """
        Calls the Node.js gateway to submit a transaction with specific identity.
        """
        self.logger.info(f"Invoking {function_name} as {user_id}@{org_name}")
        
        try:
            async with httpx.AsyncClient(timeout=45.0) as client:
                headers = {
                    "X-Org-Name": org_name,
                    "X-User-ID": user_id
                }
                response = await client.post(
                    f"{self.gateway_url}/invoke",
                    json={"function": function_name, "args": args},
                    headers=headers
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            self.logger.error(f"Error invoking transaction: {str(e)}")
            return {"success": False, "error": str(e)}

    async def query_ledger(self, function_name: str, args: List[str], org_name: str = "producteurs", user_id: str = "Admin") -> Any:
        """
        Calls the Node.js gateway to evaluate a transaction (query) with specific identity.
        """
        self.logger.info(f"Querying {function_name} as {user_id}@{org_name}")
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                headers = {
                    "X-Org-Name": org_name,
                    "X-User-ID": user_id
                }
                response = await client.post(
                    f"{self.gateway_url}/query",
                    json={"function": function_name, "args": args},
                    headers=headers
                )
                response.raise_for_status()
                data = response.json()
                return data.get("result") if data.get("success") else data
        except Exception as e:
            self.logger.error(f"Error querying ledger: {str(e)}")
            return {"success": False, "error": str(e)}

    async def register_user(self, user_id: str, org_name: str, role: str = "client") -> Dict[str, Any]:
        """
        Calls the Node.js gateway to register and enroll a new user via CA.
        """
        self.logger.info(f"Registering new user {user_id} in {org_name}")
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.gateway_url}/register",
                    json={"userId": user_id, "orgName": org_name, "role": role}
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            self.logger.error(f"Error registering user: {str(e)}")
            return {"success": False, "error": str(e)}

    # --- Wrapper methods matching the chaincode ---


    async def create_lot(self, data: Dict, org_name: str = "producteurs", user_id: str = "Admin"):
        args = [
            data['lot_hash'], data['farmer_id'], json.dumps(data['gps']),
            str(data['poids_kg']), data['espece'], data['date_collecte'],
            data['media_hash'], data.get('coop_id', "")
        ]
        return await self.invoke_transaction("CreateLot", args, org_name, user_id)

    async def get_lot(self, lot_hash: str, org_name: str = "producteurs", user_id: str = "Admin"):
        return await self.query_ledger("GetLot", [lot_hash], org_name, user_id)

    async def create_transfer(self, data: Dict, org_name: str = "producteurs", user_id: str = "Admin"):
        args = [
            data['transfer_hash'], json.dumps(data['lot_hashes']),
            data['expediteur_id'], data['destinataire_id'], data['preuve_hash']
        ]
        return await self.invoke_transaction("CreateTransfer", args, org_name, user_id)

    async def get_history(self, asset_hash: str, org_name: str = "producteurs", user_id: str = "Admin"):
        return await self.query_ledger("GetHistoryForAsset", [asset_hash], org_name, user_id)

    async def query_lots_by_status(self, status: str):
        return await self.query_ledger("QueryLotsByStatus", [status])

    async def get_eudr_report(self, lot_hash: str, org_name: str = "ministere", user_id: str = "Admin") -> Dict[str, Any]:
        """
        Aggregates data for EUDR. Defaulting to 'ministere' to ensure we get private GPS data if authorized.
        """
        lot = await self.get_lot(lot_hash, org_name, user_id)
        if not lot or "error" in lot:
            return {"success": False, "error": "LOT_NOT_FOUND"}
            
        history = await self.get_history(lot_hash, org_name, user_id)
        certifications = await self.query_ledger("QueryCertifications", [lot_hash], org_name, user_id)
        
        # Check if private data (GPS) is present
        has_private_access = "gps" in lot
        
        return {
            "success": True,
            "report_timestamp": lot.get("dateCollecte"),
            "compliance_status": "COMPLIANT" if certifications else "PENDING_VERIFICATION",
            "access_level": "FULL" if has_private_access else "REDACTED",
            "data": {
                "lot": lot,
                "history": history,
                "certifications": certifications
            },
            "proof_hash": lot_hash
        }
