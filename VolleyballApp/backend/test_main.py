import pytest
from fastapi.testclient import TestClient
from main import app
import os
import json
import uuid

client = TestClient(app)

def test_update_action_success(tmp_path):
    video_path = str(tmp_path / "test_video.mp4")
    json_path = str(tmp_path / "test_video_analysis.json")

    # Touch video
    with open(video_path, 'w') as f: f.write("dummy")

    data = {
        "actions": [
            {"id": "a1", "type": "SERVE", "start_ms": 0.0, "end_ms": 1.0},
            {"id": "a2", "type": "RECEIVE", "start_ms": 1.0, "end_ms": 2.0}
        ]
    }
    with open(json_path, 'w') as f:
        json.dump(data, f)

    response = client.post("/update_action", json={
        "video_path": video_path,
        "action_id": "a2",
        "new_type": "SPIKE",
        "new_start_ms": 1.5,
        "new_end_ms": 2.5
    })

    assert response.status_code == 200

    # Check if written to file
    with open(json_path, 'r') as f:
        updated_data = json.load(f)

    assert updated_data["actions"][1]["type"] == "SPIKE"
    assert updated_data["actions"][1]["start_ms"] == 1.5

def test_update_action_not_found(tmp_path):
    video_path = str(tmp_path / "test_video.mp4")
    json_path = str(tmp_path / "test_video_analysis.json")

    # Touch video
    with open(video_path, 'w') as f: f.write("dummy")

    data = {
        "actions": [
            {"id": "a1", "type": "SERVE", "start_ms": 0.0, "end_ms": 1.0},
        ]
    }
    with open(json_path, 'w') as f:
        json.dump(data, f)

    response = client.post("/update_action", json={
        "video_path": video_path,
        "action_id": "non_existent",
        "new_type": "SPIKE",
        "new_start_ms": 1.5,
        "new_end_ms": 2.5
    })

    assert response.status_code == 404
