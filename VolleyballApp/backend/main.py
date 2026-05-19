import warnings
warnings.filterwarnings("ignore", category=UserWarning, module="google.protobuf")
import json
import time
import logging
import asyncio
import logging
import os
import uuid
import threading
import concurrent.futures
import anyio
from anyio import Path
from typing import Dict, Any
from fastapi import FastAPI, BackgroundTasks, HTTPException, Query, Path as APIPath, Response
from fastapi import FastAPI, BackgroundTasks, HTTPException, Query, Path as APIPath, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from engine import VolleyballAnalyticsEngine
from config import ALLOWED_ORIGINS
from database import JobStore

app = FastAPI(title="Volleyball Action Detection API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory job state (In production, replace with DB/Redis)
analysis_jobs: Dict[str, Dict[str, Any]] = {}

MODELS_DIR = os.path.join(os.path.dirname(__file__), 'models')
engine = VolleyballAnalyticsEngine(models_dir=MODELS_DIR)

class AnalyzeRequest(BaseModel):
    video_path: str = Field(..., max_length=2048)

class UpdateActionRequest(BaseModel):
    video_path: str = Field(..., max_length=2048)
    action_id: str = Field(..., max_length=100)
    new_type: str = Field(..., max_length=100)
    new_start_ms: float
    new_end_ms: float

def secure_path(file_path: str) -> str:
    """Validates that the given path does not contain directory traversal characters."""
    if ".." in file_path:
        raise HTTPException(status_code=400, detail="Invalid path provided.")
    if "\x00" in file_path:
        raise HTTPException(status_code=400, detail="Invalid path provided.")
    return file_path

def get_json_path(video_path: str) -> str:
    """Returns the associated json path for the given video file."""
    base, _ = os.path.splitext(video_path)
    return f"{base}_analysis.json"

def process_video_task(job_id: str, video_path: str):
    try:
        job_store.update_job(job_id, {
            "status": "processing",
            "progress": 0.0,
            "eta_seconds": None
        })
        start_time = time.time()

        def update_progress(current_frame, total_frames):
            if total_frames > 0:
                progress = current_frame / total_frames
                elapsed = time.time() - start_time
                eta = None
                if progress > 0:
                    total_estimated = elapsed / progress
                    eta = round(max(0.0, total_estimated - elapsed))

                job_store.update_job(job_id, {
                    "progress": round(progress, 3),
                    "eta_seconds": eta
                })

        result = engine.process_video(video_path, progress_callback=update_progress)
        
        # Save exact path relative to video 
        json_path = get_json_path(video_path)

        with _file_lock:
            with open(json_path, 'w') as f:
                # ⚡ Bolt Optimization: Removed indent=4
                # Indentation formatting adds significant CPU and I/O overhead
                # which unnecessarily blocks the event loop and reduces performance.
                json.dump(result, f)

            # Populate cache
            _parsed_json_cache[json_path] = result
            _action_dict_cache[json_path] = {
                action["id"]: action for action in result.get("actions", [])
            }
            
        job_store.update_job(job_id, {
            "status": "completed",
            "progress": 1.0,
            "result": result,
            "json_path": json_path
        })
    except Exception as e:
        analysis_jobs[job_id]["status"] = "error"
        analysis_jobs[job_id]["error"] = str(e)


@app.post("/analyze")
async def analyze_video(request: AnalyzeRequest, background_tasks: BackgroundTasks):
    validate_safe_path(request.video_path)
    if not os.path.exists(request.video_path):
        raise HTTPException(status_code=404, detail="Video file not found.")

    json_path = get_json_path(safe_video_path)
    
    # If already processed, return it immediately
    if await asyncio.to_thread(os.path.exists, json_path):
        return {"status": "completed", "json_path": json_path}

    job_id = str(uuid.uuid4())
    job_store.set_job(job_id, {
        "status": "pending",
        "progress": 0.0,
        "video_path": safe_video_path
    })
    background_tasks.add_task(process_video_task, job_id, safe_video_path)
    return {"job_id": job_id, "status": "pending"}


@app.get("/job/{job_id}")
async def get_job_status(job_id: str = APIPath(..., max_length=100)):
    if job_id not in analysis_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    return job


@app.get("/ping")
async def ping():
    return {"status": "ok"}


@app.get("/results")
def get_results(video_path: str = Query(..., max_length=2048)):
    video_path = secure_path(video_path)
    json_path = get_json_path(video_path)

    with _file_lock:
        if json_path in _parsed_json_cache:
            data = _parsed_json_cache[json_path]
        else:
            try:
                with open(json_path, 'r') as f:
                    data = json.load(f)

                _parsed_json_cache[json_path] = data
                _action_dict_cache[json_path] = {
                    action["id"]: action for action in data.get("actions", [])
                }
            except FileNotFoundError:
                raise HTTPException(status_code=404, detail="Analysis results not found.")
            except json.JSONDecodeError:
                raise HTTPException(status_code=500, detail="Invalid JSON format in analysis results.")

    # ⚡ Bolt Optimization: Bypass FastAPI's slow default JSON serialization for large results
    # and perform serialization outside of the thread lock to prevent blocking event loops.
    with concurrent.futures.ProcessPoolExecutor() as executor:
        json_str = executor.submit(json.dumps, data).result()
    return Response(content=json_str, media_type="application/json")

@app.post("/update_action")
def update_action(req: UpdateActionRequest):
    safe_video_path = secure_path(req.video_path)
    json_path = get_json_path(safe_video_path)

    with _file_lock:
        if json_path not in _parsed_json_cache:
            try:
                with open(json_path, 'r') as f:
                    data = json.load(f)

                _parsed_json_cache[json_path] = data
                _action_dict_cache[json_path] = {
                    action["id"]: action for action in data.get("actions", [])
                }
            except FileNotFoundError:
                raise HTTPException(status_code=404, detail="Analysis results not found.")
            except json.JSONDecodeError:
                raise HTTPException(status_code=500, detail="Invalid JSON format in analysis results.")

        data = _parsed_json_cache[json_path]
        actions_dict = _action_dict_cache[json_path]

        action = actions_dict.get(req.action_id)
        if not action:
            raise HTTPException(status_code=404, detail="Action ID not found.")
            
        action["type"] = req.new_type
        action["start_ms"] = req.new_start_ms
        action["end_ms"] = req.new_end_ms

        # Write updated data back to disk
        with open(json_path, 'w') as f:
            # ⚡ Bolt Optimization: Removed indent=4
            # Indentation formatting adds significant CPU and I/O overhead
            # which unnecessarily blocks the event loop and reduces performance.
            json.dump(data, f)

    return {"status": "success"}

if __name__ == "__main__":
    import uvicorn
    # Make sure to run the uvicorn server in a separate terminal process
    uvicorn.run(app, host="127.0.0.1", port=8001)
