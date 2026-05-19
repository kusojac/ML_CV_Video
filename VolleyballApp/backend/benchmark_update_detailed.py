import json
import time
import os
import uuid
import sys

def run_detailed_benchmark():
    num_actions = 100000
    json_path = f"test_video_{uuid.uuid4().hex}_analysis.json"
    target_id = f"action_{num_actions - 1}"

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

    start = time.time()
    with open(json_path, 'r') as f:
        loaded_data = json.load(f)
    print(f"JSON Load: {time.time() - start:.6f}s")

    start = time.time()
    found = False
    for action in loaded_data.get("actions", []):
        if action.get("id") == target_id:
            action["type"] = "SPIKE"
            action["start_ms"] = 10.0
            action["end_ms"] = 20.0
            found = True
            break
    print(f"Linear Search: {time.time() - start:.6f}s")

    start = time.time()
    with open(json_path, 'w') as f:
        json.dump(loaded_data, f, indent=4)
    print(f"JSON Dump: {time.time() - start:.6f}s")

    os.remove(json_path)

if __name__ == "__main__":
    run_detailed_benchmark()
