import requests
import json
import time
import os

BASE_URL = "http://localhost:8000/api/v1"

def test_root():
    print("\n--- [1] Testing Root Endpoint ---")
    response = requests.get("http://localhost:8000/")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

def test_ping_ledger():
    print("\n--- [0] Testing Ledger Connectivity (Ping) ---")
    # Using the audit endpoint which is a GET but maps to a query
    response = requests.get(f"{BASE_URL}/audit/query/status/COLLECTE")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

def test_register_actor():
    actor_id = f"ACTOR-TEST-{int(time.time())}"
    print(f"\n--- [2] Testing Actor Registration for {actor_id} ---")
    payload = {
        "actorIdHash": actor_id,
        "typeActeur": "PRODUCTEUR",
        "clePublique": "PUB-KEY-TEST",
        "orgName": "producteurs"
    }
    response = requests.post(f"{BASE_URL}/actors/register", json=payload)
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
    return actor_id

def test_create_lot(actor_id, image_path):
    print("\n--- [3] Testing Lot Creation ---")
    lot_hash = f"LOT-{int(time.time())}"
    
    data = {
        "lot_hash": lot_hash,
        "farmer_id": actor_id,
        "latitude": 6.123,
        "longitude": 1.234,
        "poids_kg": 50.5,
        "espece": "Forastero",
        "date_collecte": "2026-05-01",
        "coop_id": "COOP-LOME"
    }
    
    if not os.path.exists(image_path):
        print(f"Error: Image not found at {image_path}")
        return None

    with open(image_path, 'rb') as f:
        # We explicitly name the file 'test.png' to avoid path encoding issues
        files = {'file': ('test.png', f, 'image/png')}
        # Ensure all data values are strings
        data_str = {k: str(v) for k, v in data.items()}
        response = requests.post(f"{BASE_URL}/lots/", data=data_str, files=files)
    
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
    return lot_hash

def test_get_lot(lot_hash):
    print(f"\n--- [4] Testing Get Lot Details: {lot_hash} ---")
    response = requests.get(f"{BASE_URL}/lots/{lot_hash}")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

def test_audit_history(lot_hash):
    print(f"\n--- [5] Testing Audit History: {lot_hash} ---")
    response = requests.get(f"{BASE_URL}/audit/history/{lot_hash}")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

if __name__ == "__main__":
    image_path = r"C:\Users\pierr\.gemini\antigravity\brain\2dd233a4-f221-49e9-b49f-9bf413e485a3\test_cacao_batch_jpg_1777677327792.png"
    
    try:
        test_root()
        test_ping_ledger()
        actor_id = test_register_actor()
        lot_hash = test_create_lot(actor_id, image_path)
        if lot_hash:
            test_get_lot(lot_hash)
            test_audit_history(lot_hash)
    except Exception as e:
        print(f"Test failed: {e}")
