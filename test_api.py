import requests
import json

def test_registration():
    url = "http://localhost:8000/api/v1/actors/register"
    payload = {
        "actorIdHash": "ACTOR-PYTHON-FINAL-RETEST",
        "typeActeur": "TRANSFORMATEUR",
        "clePublique": "PUB-KEY-PYTHON",
        "orgName": "transformateurs"
    }
    headers = {'Content-Type': 'application/json'}

    print(f"Testing registration via Backend API: {url}...")
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=60)
        print(f"Status Code: {response.status_code}")
        print("Response Body:")
        print(json.dumps(response.json(), indent=2))
    except Exception as e:
        print(f"Error during API call: {e}")

if __name__ == "__main__":
    test_registration()
