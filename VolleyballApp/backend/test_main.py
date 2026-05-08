import pytest
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
    response = client.post("/analyze", json={"video_path": "../../../etc/nonexistent"})
    assert response.status_code == 404

def test_get_results_not_found():
    """Basic test for an existing endpoint"""
    response = client.get("/results?video_path=../../../etc/nonexistent")
    assert response.status_code == 404

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
