import time
import os
import json
import warnings
warnings.filterwarnings("ignore")

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

# Create a mock video and json file
video_path = "mock_video.mp4"
json_path = "mock_video_analysis.json"

with open(video_path, "w") as f:
    f.write("dummy")

data = {
    "actions": [
        {"id": "1", "type": "spike", "start_ms": 100, "end_ms": 200}
    ]
}
with open(json_path, "w") as f:
    json.dump(data, f)

def benchmark_endpoint(iterations=1000):
    start = time.time()
    for _ in range(iterations):
        response = client.post(
            "/update_action",
            json={
                "video_path": video_path,
                "action_id": "1",
                "new_type": "block",
                "new_start_ms": 150,
                "new_end_ms": 250
            }
        )
        assert response.status_code == 200
    return time.time() - start

print(f"Time for {1000} requests: {benchmark_endpoint()} seconds")

os.remove(video_path)
os.remove(json_path)
