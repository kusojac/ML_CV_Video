import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_analyze_not_found():
    response = client.post("/analyze", json={"video_path": "nonexistent.mp4"})
    assert response.status_code == 404
