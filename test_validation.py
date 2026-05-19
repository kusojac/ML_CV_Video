import pytest
from fastapi.testclient import TestClient
from VolleyballApp.backend.main import app

client = TestClient(app)

def test_too_long_video_path_analyze():
    response = client.post("/analyze", json={"video_path": "a" * 2000})
    assert response.status_code == 422

def test_too_long_job_id():
    response = client.get(f"/job/{'a'*300}")
    assert response.status_code == 422

def test_too_long_video_path_results():
    response = client.get(f"/results?video_path={'a'*2000}")
    assert response.status_code == 422

def test_too_long_action_id():
    response = client.post("/update_action", json={
        "video_path": "test.mp4",
        "action_id": "a" * 300,
        "new_type": "serve",
        "new_start_ms": 100.0,
        "new_end_ms": 200.0
    })
    assert response.status_code == 422
