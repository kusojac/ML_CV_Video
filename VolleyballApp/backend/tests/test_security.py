from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_analyze_path_traversal():
    response = client.post("/analyze", json={"video_path": "../../../etc/passwd"})
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid path provided."}

def test_results_path_traversal():
    response = client.get("/results?video_path=../../../etc/passwd")
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid path provided."}

def test_update_action_path_traversal():
    response = client.post("/update_action", json={
        "video_path": "../../../etc/passwd",
        "action_id": "test",
        "new_type": "test",
        "new_start_ms": 0.0,
        "new_end_ms": 1.0
    })
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid path provided."}

def test_absolute_path_allowed():
    # Should not return 400, but 404 because file doesn't exist
    response = client.post("/analyze", json={"video_path": "/var/log/syslog"})
    assert response.status_code == 404

def test_analyze_dos():
    long_path = "a" * 5000
    response = client.post("/analyze", json={"video_path": long_path})
    assert response.status_code == 422 # Unprocessable Entity

def test_results_dos():
    long_path = "a" * 5000
    response = client.get(f"/results?video_path={long_path}")
    assert response.status_code == 422 # Unprocessable Entity
