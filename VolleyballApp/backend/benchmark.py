import asyncio
import time
import httpx
import json

# Create a large dummy json
dummy_json = {"actions": []}
for i in range(500000): # Make it fairly large to block for ~0.1-0.5s
    dummy_json["actions"].append({
        "id": f"action_{i}",
        "type": "spike",
        "start_ms": 100.0,
        "end_ms": 200.0
    })

with open("dummy_analysis.json", "w") as f:
    json.dump(dummy_json, f)

async def run_benchmark():
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000", timeout=30.0) as client:
        # Warmup
        try:
            await client.get("/job/non_existent")
        except:
            pass

        async def ping():
            start = time.time()
            res = await client.get("/job/non_existent")
            return time.time() - start

        async def update():
            start = time.time()
            res = await client.post("/update_action", json={
                "video_path": "dummy.mp4",
                "action_id": "action_99999",
                "new_type": "block",
                "new_start_ms": 150.0,
                "new_end_ms": 250.0
            })
            return time.time() - start

        # Fix benchmark logic based on review
        update_task = asyncio.create_task(update())
        await asyncio.sleep(0.01)

        ping_tasks = [asyncio.create_task(ping()) for _ in range(10)]
        ping_times = await asyncio.gather(*ping_tasks)
        update_time = await update_task

        print(f"Update time: {update_time:.3f}s")
        print(f"Average ping time during update: {sum(ping_times)/len(ping_times):.3f}s")
        print(f"Max ping time: {max(ping_times):.3f}s")

if __name__ == "__main__":
    asyncio.run(run_benchmark())
