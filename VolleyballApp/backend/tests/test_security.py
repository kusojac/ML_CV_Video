import sys
from unittest.mock import MagicMock

# Mock dependencies
sys.modules['cv2'] = MagicMock()
sys.modules['math'] = MagicMock()
sys.modules['onnxruntime'] = MagicMock()
sys.modules['pickle'] = MagicMock()
sys.modules['mediapipe'] = MagicMock()
sys.modules['numpy'] = MagicMock()

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_directory_traversal_analyze():
    response = client.post("/analyze", json={"video_path": "../../../etc/passwd"})
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid path: Directory traversal is not allowed."

def test_directory_traversal_results():
    response = client.get("/results", params={"video_path": "../../../etc/passwd"})
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid path: Directory traversal is not allowed."

def test_directory_traversal_update_action():
    response = client.post("/update_action", json={
        "video_path": "../../../etc/passwd",
        "action_id": "test",
        "new_type": "test",
        "new_start_ms": 0.0,
        "new_end_ms": 1.0
    })
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid path: Directory traversal is not allowed."
