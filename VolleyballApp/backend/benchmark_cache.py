import json
import time
import os
import uuid

_parsed_json_cache = {}
_action_dict_cache = {}

def get_video_data(json_path: str):
    if json_path in _parsed_json_cache:
        return _parsed_json_cache[json_path], _action_dict_cache[json_path]

    with open(json_path, 'r') as f:
        data = json.load(f)

    action_dict = {action["id"]: action for action in data.get("actions", []) if "id" in action}

    _parsed_json_cache[json_path] = data
    _action_dict_cache[json_path] = action_dict
    return data, action_dict

def run_cache_benchmark():
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

    # Cold run to show baseline equivalent
    start = time.time()
    with open(json_path, 'r') as f:
        cold_data = json.load(f)
    for a in cold_data.get("actions", []):
        if a.get("id") == target_id:
            break
    print(f"Baseline Load + Linear Search: {time.time() - start:.6f}s")

    # Cache miss
    start = time.time()
    data, action_dict = get_video_data(json_path)
    print(f"Cold Cache Load + Build Dict: {time.time() - start:.6f}s")

    # Cache hit
    start = time.time()
    data, action_dict = get_video_data(json_path)
    action = action_dict.get(target_id)
    if action:
        action["type"] = "SPIKE"
        action["start_ms"] = 10.0
        action["end_ms"] = 20.0
    print(f"Warm Cache Load + Dict Lookup: {time.time() - start:.6f}s")

    start = time.time()
    with open(json_path, 'w') as f:
        json.dump(data, f, indent=4)
    print(f"JSON Dump: {time.time() - start:.6f}s")

    os.remove(json_path)

if __name__ == "__main__":
    run_cache_benchmark()
