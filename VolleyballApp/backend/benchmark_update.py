import json
import time
import os
import uuid
import sys
from main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def setup_benchmark_data(num_actions=100000):
    video_path = f"test_video_{uuid.uuid4()}.mp4"
    json_path = f"test_video_{uuid.uuid4().hex}_analysis.json"

    # Hack the get_json_path to point to our test json path
    import main
    original_get_json_path = main.get_json_path
    main.get_json_path = lambda p: json_path if p == video_path else original_get_json_path(p)

    data = {
        "actions": []
    }
    for i in range(num_actions):
        data["actions"].append({
            "id": f"action_{i}",
            "type": "NONE",
            "start_ms": 0.0,
            "end_ms": 100.0
        })

    with open(json_path, 'w') as f:
        json.dump(data, f)

    return video_path, json_path, main, original_get_json_path

def run_benchmark():
    num_actions = 100000
    video_path, json_path, main_module, orig_func = setup_benchmark_data(num_actions)

    # Target the last action to simulate worst-case linear search
    target_id = f"action_{num_actions - 1}"

    start_time = time.time()
    response = client.post("/update_action", json={
        "video_path": video_path,
        "action_id": target_id,
        "new_type": "SPIKE",
        "new_start_ms": 10.0,
        "new_end_ms": 20.0
    })
    end_time = time.time()

    if response.status_code != 200:
        print("Error:", response.json())
        sys.exit(1)

    duration = end_time - start_time
    print(f"Update Action time (worst case): {duration:.6f} seconds")

    # cleanup
    os.remove(json_path)
    main_module.get_json_path = orig_func

if __name__ == "__main__":
    run_benchmark()
