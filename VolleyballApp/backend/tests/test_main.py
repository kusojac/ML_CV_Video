import pytest
import json
from unittest.mock import patch

from main import process_video_task, analysis_jobs
from main import app, secure_path
from fastapi import HTTPException
from fastapi.testclient import TestClient

client = TestClient(app)

def test_process_video_task_error_handling():
    job_id = "test_job_error"
    video_path = "dummy_video.mp4"

    analysis_jobs[job_id] = {
        "status": "pending",
        "progress": 0.0,
        "video_path": video_path
    }

    # Instead of patching main.engine.process_video, let's patch process_video directly on the class
    with patch("engine.VolleyballAnalyticsEngine.process_video") as mock_process_video:
        mock_process_video.side_effect = Exception("Test error processing video")

        process_video_task(job_id, video_path)

    assert analysis_jobs[job_id]["status"] == "error"
    assert analysis_jobs[job_id]["error"] == "An internal error occurred during video processing."

def test_process_video_task_success(tmp_path):
    job_id = "test_job_success"
    video_path = str(tmp_path / "test_video.mp4")

    analysis_jobs[job_id] = {
        "status": "pending",
        "progress": 0.0,
        "video_path": video_path
    }

    mock_result = {"actions": [{"id": "1", "type": "spike"}]}

    with patch("engine.VolleyballAnalyticsEngine.process_video") as mock_process_video, \
         patch("main.get_json_path") as mock_get_json_path:

        mock_process_video.return_value = mock_result
        json_path = str(tmp_path / "test_video_analysis.json")
        mock_get_json_path.return_value = json_path

        process_video_task(job_id, video_path)

    assert analysis_jobs[job_id]["status"] == "completed"
    assert analysis_jobs[job_id]["progress"] == 1.0
    assert analysis_jobs[job_id]["result"] == mock_result
    assert analysis_jobs[job_id]["json_path"] == json_path

    with open(json_path, 'r') as f:
        data = json.load(f)
    assert data == mock_result
from fastapi.testclient import TestClient
from main import app, secure_path
from fastapi import HTTPException

client = TestClient(app)

def test_validate_safe_path_valid():
    assert secure_path("C:/Users/test/video.mp4") == "C:/Users/test/video.mp4"
    assert secure_path("video.mp4") == "video.mp4"

def test_validate_safe_path_invalid():
    with pytest.raises(HTTPException) as excinfo:
        secure_path("../../etc/passwd")
    assert excinfo.value.status_code == 400



def test_validate_safe_path_null_byte():
    with pytest.raises(HTTPException) as excinfo:
        secure_path("video\x00.mp4")
    assert excinfo.value.status_code == 400
    assert excinfo.value.detail == "Invalid path provided."

def test_analyze_null_byte():
    response = client.post("/analyze", json={"video_path": "video\x00.mp4"})
    assert response.status_code == 400
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

def test_invalid_json_handling_get_results(tmp_path):
    video_path = "test_invalid.mp4"
    json_path = tmp_path / "test_invalid_analysis.json"
    with open(json_path, "w") as f:
        f.write("{ invalid json }")
    with patch("main.get_json_path") as mock_get_json_path:
        mock_get_json_path.return_value = str(json_path)
        response = client.get(f"/results?video_path={video_path}")
        assert response.status_code == 500
        assert response.json() == {"detail": "Invalid JSON format in analysis results."}

def test_invalid_json_handling_update_action(tmp_path):
    video_path = "test_invalid.mp4"
    json_path = tmp_path / "test_invalid_analysis.json"
    with open(json_path, "w") as f:
        f.write("{ invalid json }")
    with patch("main.get_json_path") as mock_get_json_path:
        mock_get_json_path.return_value = str(json_path)
        response = client.post("/update_action", json={
            "video_path": video_path,
            "action_id": "123",
            "new_type": "Serve",
            "new_start_ms": 1.0,
            "new_end_ms": 2.0
        })
        assert response.status_code == 500
        assert response.json() == {"detail": "Invalid JSON format in analysis results."}

def test_max_length_validation_analyze_request():
    response = client.post("/analyze", json={"video_path": "a" * 2049})
    assert response.status_code == 422

def test_max_length_validation_update_action_request():
    response = client.post("/update_action", json={
        "video_path": "a" * 2049,
        "action_id": "123",
        "new_type": "Serve",
        "new_start_ms": 1.0,
        "new_end_ms": 2.0
    })
    assert response.status_code == 422

    response = client.post("/update_action", json={
        "video_path": "a.mp4",
        "action_id": "a" * 101,
        "new_type": "Serve",
        "new_start_ms": 1.0,
        "new_end_ms": 2.0
    })
    assert response.status_code == 422

    response = client.post("/update_action", json={
        "video_path": "a.mp4",
        "action_id": "123",
        "new_type": "a" * 101,
        "new_start_ms": 1.0,
        "new_end_ms": 2.0
    })
    assert response.status_code == 422

def test_max_length_validation_job_id():
    response = client.get(f"/job/{'a' * 101}")
    assert response.status_code == 422

def test_max_length_validation_get_results():
    response = client.get(f"/results?video_path={'a' * 2049}")
    assert response.status_code == 422
