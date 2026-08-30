import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_results_oserror(mocker):
    # Mock open to raise an OSError (e.g., PermissionError or IsADirectoryError)
    mocker.patch("builtins.open", side_effect=OSError("Permission denied"))
    response = client.get("/results?video_path=some_video.mp4")
    assert response.status_code == 404
    assert response.json() == {"detail": "Analysis results not found."}

def test_update_action_oserror(mocker):
    # Mock open to raise an OSError
    mocker.patch("builtins.open", side_effect=OSError("Permission denied"))
    response = client.post("/update_action", json={
        "video_path": "some_video.mp4",
        "action_id": "test",
        "new_type": "test",
        "new_start_ms": 0.0,
        "new_end_ms": 1.0
    })
    assert response.status_code == 404
    assert response.json() == {"detail": "Analysis results not found."}
