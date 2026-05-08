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
        assert response.json()["detail"] == "Error decoding analysis results."
    finally:
        if os.path.exists(json_path):
            os.remove(json_path)

def test_get_job_status_not_found():
    """Test that requesting an invalid or non-existent job ID returns 404."""
    response = client.get("/job/nonexistent-job-id-1234")
    assert response.status_code == 404
    assert response.json()["detail"] == "Job not found"
