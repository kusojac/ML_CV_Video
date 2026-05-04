import pytest
from fastapi.testclient import TestClient
from main import app, secure_path
from fastapi import HTTPException

client = TestClient(app)

def test_secure_path_valid():
    assert secure_path("C:/Users/test/video.mp4") == "C:/Users/test/video.mp4"
    assert secure_path("video.mp4") == "video.mp4"

def test_secure_path_invalid():
    with pytest.raises(HTTPException) as excinfo:
        secure_path("../../etc/passwd")
    assert excinfo.value.status_code == 400
    assert "Directory traversal is not allowed" in excinfo.value.detail

def test_analyze_path_traversal():
    response = client.post("/analyze", json={"video_path": "../../secret.txt"})
    assert response.status_code == 400

def test_results_path_traversal():
    response = client.get("/results?video_path=../../secret.txt")
    assert response.status_code == 400

def test_update_action_path_traversal():
    response = client.post("/update_action", json={
        "video_path": "../../secret.txt",
        "action_id": "123",
        "new_type": "Serve",
        "new_start_ms": 1.0,
        "new_end_ms": 2.0
    })
    assert response.status_code == 400
