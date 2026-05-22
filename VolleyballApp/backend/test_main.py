import os
import sys
from fastapi.testclient import TestClient

# Mock out dependencies that fail locally (like cv2, mediapipe, engine)
import unittest.mock as mock

# We mock engine module before importing main
mock_engine = mock.MagicMock()
sys.modules['engine'] = mock_engine

# Now we can import main
from main import app
from config import ALLOWED_ORIGINS

client = TestClient(app)

def test_cors_allowed_origin():
    """Test that requests from an allowed origin succeed."""
    # Assuming http://localhost:8001 is in the default allowed origins
    origin = ALLOWED_ORIGINS[0] if ALLOWED_ORIGINS else "http://localhost:8001"
    response = client.options(
        "/analyze",
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "POST",
        },
    )
    assert response.status_code == 200

def test_cors_disallowed_origin():
    """Test that requests from a disallowed origin fail."""
    response = client.options(
        "/analyze",
        headers={
            "Origin": "http://malicious.evil.website.com",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert response.status_code == 400

def test_analyze_video_not_found():
    """Basic test for an existing endpoint"""
    response = client.post("/analyze", json={"video_path": "dummy_nonexistent.mp4"})
    assert response.status_code == 404

def test_get_results_not_found():
    """Basic test for an existing endpoint"""
    response = client.get("/results?video_path=dummy_nonexistent.mp4")
    assert response.status_code == 404

def test_get_results_invalid_json():
    """Test that requesting results with an invalid JSON file returns 500."""
    video_path = "dummy_invalid.mp4"
    json_path = "dummy_invalid_analysis.json"

    # Create invalid JSON
    with open(json_path, "w") as f:
        f.write("{invalid_json:")

    try:
        response = client.get(f"/results?video_path={video_path}")
        assert response.status_code == 500
        assert response.json()["detail"] == "Invalid JSON format in analysis results."
    finally:
        if os.path.exists(json_path):
            os.remove(json_path)

def test_analyze_video_path_traversal():
    """Test path traversal is blocked in analyze endpoint"""
    response = client.post("/analyze", json={"video_path": "../../../etc/passwd"})
    assert response.status_code == 400

def test_get_results_path_traversal():
    """Test path traversal is blocked in results endpoint"""
    response = client.get("/results?video_path=../../../etc/passwd")
    assert response.status_code == 400

def test_get_job_status_not_found():
    """Test that requesting an invalid or non-existent job ID returns 404."""
    response = client.get("/job/nonexistent-job-id-1234")
    assert response.status_code == 404
    assert response.json()["detail"] == "Job not found"

def test_update_action_success():
    """Test updating an existing action successfully."""
    import json

    # Create mock analysis file
    video_path = "test_video.mp4"
    json_path = "test_video_analysis.json"
    mock_data = {
        "actions": [
            {
                "id": "action123",
                "type": "serve",
                "start_ms": 1000.0,
                "end_ms": 2000.0
            }
        ]
    }
    with open(json_path, "w") as f:
        json.dump(mock_data, f)

    try:
        response = client.post(
            "/update_action",
            json={
                "video_path": video_path,
                "action_id": "action123",
                "new_type": "spike",
                "new_start_ms": 1500.0,
                "new_end_ms": 2500.0
            }
        )
        assert response.status_code == 200
        assert response.json()["status"] == "success"

        # Verify that file was updated
        with open(json_path, "r") as f:
            updated_data = json.load(f)

        updated_action = updated_data["actions"][0]
        assert updated_action["type"] == "spike"
        assert updated_action["start_ms"] == 1500.0
        assert updated_action["end_ms"] == 2500.0
    finally:
        # Clean up
        if os.path.exists(json_path):
            os.remove(json_path)

def test_update_action_with_key_points():
    """Test updating an action including key points successfully."""
    import json

    video_path = "test_video.mp4"
    json_path = "test_video_analysis.json"
    mock_data = {
        "actions": [
            {
                "id": "action123",
                "type": "serve",
                "start_ms": 1000.0,
                "end_ms": 2000.0,
                "key_points": []
            }
        ]
    }
    with open(json_path, "w") as f:
        json.dump(mock_data, f)

    try:
        key_points = [
            {
                "id": "kp1",
                "description": "Zla pozycja",
                "time_ms": 1200.0,
                "player_box": [10.0, 20.0, 30.0, 40.0]
            }
        ]
        response = client.post(
            "/update_action",
            json={
                "video_path": video_path,
                "action_id": "action123",
                "new_type": "serve",
                "new_start_ms": 1000.0,
                "new_end_ms": 2000.0,
                "new_key_points": key_points
            }
        )
        assert response.status_code == 200
        assert response.json()["status"] == "success"

        # Verify that file was updated
        with open(json_path, "r") as f:
            updated_data = json.load(f)

        updated_action = updated_data["actions"][0]
        assert "key_points" in updated_action
        assert len(updated_action["key_points"]) == 1
        assert updated_action["key_points"][0]["id"] == "kp1"
        assert updated_action["key_points"][0]["description"] == "Zla pozycja"
        assert updated_action["key_points"][0]["time_ms"] == 1200.0
        assert updated_action["key_points"][0]["player_box"] == [10.0, 20.0, 30.0, 40.0]
    finally:
        # Clean up
        if os.path.exists(json_path):
            os.remove(json_path)

def test_update_action_not_found_file():
    """Test updating an action when analysis file is missing."""
    response = client.post(
        "/update_action",
        json={
            "video_path": "nonexistent_video.mp4",
            "action_id": "action123",
            "new_type": "spike",
            "new_start_ms": 1500.0,
            "new_end_ms": 2500.0
        }
    )
    assert response.status_code == 404
    assert response.json()["detail"] == "Analysis results not found."

def test_update_action_not_found_action():
    """Test updating an action that does not exist in the analysis file."""
    import json

    video_path = "test_video.mp4"
    json_path = "test_video_analysis.json"
    mock_data = {
        "actions": [
            {
                "id": "action123",
                "type": "serve",
                "start_ms": 1000.0,
                "end_ms": 2000.0
            }
        ]
    }
    with open(json_path, "w") as f:
        json.dump(mock_data, f)

    try:
        response = client.post(
            "/update_action",
            json={
                "video_path": video_path,
                "action_id": "nonexistent_action",
                "new_type": "spike",
                "new_start_ms": 1500.0,
                "new_end_ms": 2500.0
            }
        )
        assert response.status_code == 404
        assert response.json()["detail"] == "Action ID not found."
    finally:
        if os.path.exists(json_path):
            os.remove(json_path)

def test_job_persistence():
    """Test that job state is maintained across JobStore re-initialization."""
    from database import JobStore
    import uuid

    db_path = "test_jobs.db"
    if os.path.exists(db_path):
        os.remove(db_path)

    try:
        job_id = str(uuid.uuid4())
        store = JobStore(db_path)
        store.set_job(job_id, {"status": "pending", "progress": 0.0, "video_path": "test.mp4"})

        # Simulate restart by creating new store instance
        store2 = JobStore(db_path)
        job = store2.get_job(job_id)

        assert job is not None
        assert job["status"] == "pending"
        assert job["progress"] == 0.0
        assert job["video_path"] == "test.mp4"
    finally:
        if os.path.exists(db_path):
            os.remove(db_path)
