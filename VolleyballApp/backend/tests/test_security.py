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

def test_security_headers():
    response = client.get("/ping")
    assert response.status_code == 200
    assert response.headers.get("X-Content-Type-Options") == "nosniff"
    assert response.headers.get("X-Frame-Options") == "DENY"
    assert response.headers.get("Strict-Transport-Security") == "max-age=31536000; includeSubDomains"
    assert response.headers.get("X-XSS-Protection") == "1; mode=block"
    assert response.headers.get("Content-Security-Policy") == "default-src 'none'"

def test_security_headers_docs():
    response = client.get("/docs")
    assert response.status_code == 200
    assert "Content-Security-Policy" not in response.headers

    response = client.get("/redoc")
    assert response.status_code == 200
    assert "Content-Security-Policy" not in response.headers

    response = client.get("/openapi.json")
    assert response.status_code == 200
    assert "Content-Security-Policy" not in response.headers

def test_update_action_dos_player_id():
    response = client.post("/update_action", json={
        "video_path": "a.mp4",
        "action_id": "123",
        "new_type": "Serve",
        "new_start_ms": 1.0,
        "new_end_ms": 2.0,
        "new_player_id": "a" * 101
    })
    assert response.status_code == 422

def test_update_action_dos_active_focus_id():
    response = client.post("/update_action", json={
        "video_path": "a.mp4",
        "action_id": "123",
        "new_type": "Serve",
        "new_start_ms": 1.0,
        "new_end_ms": 2.0,
        "new_active_focus_id": "a" * 101
    })
    assert response.status_code == 422
