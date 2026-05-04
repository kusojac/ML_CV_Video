import pytest
import os
import json
from unittest.mock import patch

from main import process_video_task, analysis_jobs

def test_process_video_task_error_handling():
    job_id = "test_job_error"
    video_path = "dummy_video.mp4"

    # Initialize the job in the dictionary
    analysis_jobs[job_id] = {
        "status": "pending",
        "progress": 0.0,
        "video_path": video_path
    }

    # Mock engine.process_video to raise an exception
    with patch("main.engine.process_video") as mock_process_video:
        mock_process_video.side_effect = Exception("Test error processing video")

        process_video_task(job_id, video_path)

    # Check the updated state of the job
    assert analysis_jobs[job_id]["status"] == "error"
    assert analysis_jobs[job_id]["error"] == "Test error processing video"

def test_process_video_task_success(tmp_path):
    job_id = "test_job_success"
    video_path = str(tmp_path / "test_video.mp4")

    analysis_jobs[job_id] = {
        "status": "pending",
        "progress": 0.0,
        "video_path": video_path
    }

    mock_result = {"actions": [{"id": "1", "type": "spike"}]}

    with patch("main.engine.process_video") as mock_process_video, \
         patch("main.get_json_path") as mock_get_json_path:

        mock_process_video.return_value = mock_result
        json_path = str(tmp_path / "test_video_analysis.json")
        mock_get_json_path.return_value = json_path

        process_video_task(job_id, video_path)

    assert analysis_jobs[job_id]["status"] == "completed"
    assert analysis_jobs[job_id]["progress"] == 1.0
    assert analysis_jobs[job_id]["result"] == mock_result
    assert analysis_jobs[job_id]["json_path"] == json_path

    # Verify the JSON file was created
    with open(json_path, 'r') as f:
        data = json.load(f)
    assert data == mock_result
