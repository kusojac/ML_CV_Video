from unittest import mock
from fastapi.testclient import TestClient

# We mock engine module before importing main like in test_main.py,
# but since the goal is to evaluate engine initialized with mocks (if they test engine.py)
# wait, actually the legacy tests evaluate engine.py.
# If we mock engine completely, we aren't testing engine.
# Why did cv2 fail? Because mock.mock_open() patched builtins.open globally, breaking cv2!
mock_pickle = mock.patch('pickle.load').start()

# Only mock open for model.p
original_open = open
def safe_open(file, *args, **kwargs):
    if 'model.p' in str(file):
        return mock.mock_open(read_data=b"dummy")()
    return original_open(file, *args, **kwargs)

mock_open = mock.patch('builtins.open', side_effect=safe_open).start()

from main import app

client = TestClient(app)

def test_analyze_not_found():
    response = client.post("/analyze", json={"video_path": "nonexistent.mp4"})
    assert response.status_code == 404
