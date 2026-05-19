import json
import time
import os
import uuid

# Mocking the cache and functions
_results_cache = {}
_action_lookup_cache = {}

def get_json_path(video_path):
    return video_path.replace(".mp4", "_analysis.json")

def load_and_cache_results(video_path):
    if video_path in _results_cache:
        return _results_cache[video_path]

    json_path = get_json_path(video_path)
    if not os.path.exists(json_path):
        return None

    with open(json_path, 'r') as f:
        data = json.load(f)

    _results_cache[video_path] = data
    lookup = {}
    for action in data.get("actions", []):
        act_id = action.get("id")
        if act_id:
            lookup[act_id] = action
    _action_lookup_cache[video_path] = lookup
    return data

def run_cached_benchmark():
    num_actions = 100000
    video_path = f"test_video_{uuid.uuid4().hex}.mp4"
    json_path = get_json_path(video_path)
    target_id = f"action_{num_actions - 1}"

    # Create mock data
    data = {"actions": []}
    for i in range(num_actions):
        data["actions"].append({
            "id": f"action_{i}",
            "type": "NONE",
            "start_ms": 0.0,
            "end_ms": 100.0
        })
    with open(json_path, 'w') as f:
        json.dump(data, f)

    # First load (cold cache)
    start = time.time()
    load_and_cache_results(video_path)
    print(f"Cold Cache Load + Lookup Build: {time.time() - start:.6f}s")

    # Second load (warm cache)
    start = time.time()
    data = load_and_cache_results(video_path)
    lookup = _action_lookup_cache.get(video_path, {})
    action = lookup.get(target_id)
    if action:
        action["type"] = "SPIKE"
        action["start_ms"] = 10.0
        action["end_ms"] = 20.0
    print(f"Warm Cache Load + Dict Lookup: {time.time() - start:.6f}s")

    # Dump
    start = time.time()
    with open(json_path, 'w') as f:
        json.dump(data, f, indent=4)
    print(f"JSON Dump: {time.time() - start:.6f}s")

    os.remove(json_path)

if __name__ == "__main__":
    run_cached_benchmark()
