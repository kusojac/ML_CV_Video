import warnings
warnings.filterwarnings("ignore", category=UserWarning, module="google.protobuf")
import json
import time
import asyncio
import os
import uuid
import threading
import aiofiles
from typing import Dict, Any
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from engine import VolleyballAnalyticsEngine
from config import ALLOWED_ORIGINS

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

# Caches for parsed JSON data and O(1) action lookups
_parsed_json_cache: Dict[str, Any] = {}
_action_dict_cache: Dict[str, Dict[str, Any]] = {}
_file_lock = threading.Lock()

MODELS_DIR = os.path.join(os.path.dirname(__file__), 'models')
engine = VolleyballAnalyticsEngine(models_dir=MODELS_DIR)

class AnalyzeRequest(BaseModel):
    video_path: str

class UpdateActionRequest(BaseModel):
    video_path: str
    action_id: str
    new_type: str
    new_start_ms: float
    new_end_ms: float

def secure_path(file_path: str) -> str:
    """Validates that the given path does not contain directory traversal characters."""
    if ".." in file_path:
        raise HTTPException(status_code=400, detail="Directory traversal is not allowed")
    return file_path

def get_json_path(video_path: str) -> str:
    """Returns the associated json path for the given video file."""
    base, _ = os.path.splitext(video_path)
    return f"{base}_analysis.json"

def process_video_task(job_id: str, video_path: str):
    try:
        analysis_jobs[job_id]["status"] = "processing"
        analysis_jobs[job_id]["progress"] = 0.0
        analysis_jobs[job_id]["eta_seconds"] = None
        start_time = time.time()

        def update_progress(current_frame, total_frames):
            if total_frames > 0:
                progress = current_frame / total_frames
                analysis_jobs[job_id]["progress"] = round(progress, 3)
                elapsed = time.time() - start_time
                if progress > 0:
                    total_estimated = elapsed / progress
                    eta = max(0.0, total_estimated - elapsed)
                    analysis_jobs[job_id]["eta_seconds"] = round(eta)

        result = engine.process_video(video_path, progress_callback=update_progress)
        
        # Save exact path relative to video 
        json_path = get_json_path(video_path)

        with _file_lock:
            with open(json_path, 'w') as f:
                json.dump(result, f, indent=4)

            # Populate cache
            _parsed_json_cache[json_path] = result
            _action_dict_cache[json_path] = {
                action["id"]: action for action in result.get("actions", [])
            }
            
        analysis_jobs[job_id]["status"] = "completed"
        analysis_jobs[job_id]["progress"] = 1.0
        analysis_jobs[job_id]["result"] = result
        analysis_jobs[job_id]["json_path"] = json_path
    except Exception as e:
        analysis_jobs[job_id]["status"] = "error"
        analysis_jobs[job_id]["error"] = str(e)


@app.post("/analyze")
async def analyze_video(request: AnalyzeRequest, background_tasks: BackgroundTasks):
    safe_video_path = secure_path(request.video_path)
    if not os.path.exists(safe_video_path):
        raise HTTPException(status_code=404, detail="Video file not found.")

    json_path = get_json_path(safe_video_path)
    
    # If already processed, return it immediately
    if os.path.exists(json_path):
        return {"status": "completed", "json_path": json_path}

    job_id = str(uuid.uuid4())
    analysis_jobs[job_id] = {
        "status": "pending",
        "progress": 0.0,
        "video_path": safe_video_path
    }
    background_tasks.add_task(process_video_task, job_id, safe_video_path)
    return {"job_id": job_id, "status": "pending"}


@app.get("/job/{job_id}")
async def get_job_status(job_id: str):
    if job_id not in analysis_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    return analysis_jobs[job_id]


@app.get("/ping")
async def ping():
    return {"status": "ok"}


@app.get("/results")
def get_results(video_path: str):
    video_path = secure_path(video_path)
    json_path = get_json_path(video_path)

    with _file_lock:
        if json_path in _parsed_json_cache:
            return _parsed_json_cache[json_path]

        try:
            with open(json_path, 'r') as f:
                data = json.load(f)

            _parsed_json_cache[json_path] = data
            _action_dict_cache[json_path] = {
                action["id"]: action for action in data.get("actions", [])
            }
            return data
        except FileNotFoundError:
            raise HTTPException(status_code=404, detail="Analysis results not found.")
        except json.JSONDecodeError:
            raise HTTPException(status_code=500, detail="Invalid JSON format in analysis results.")

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
            json.dump(data, f, indent=4)

    return {"status": "success"}

if __name__ == "__main__":
    import uvicorn
    # Make sure to run the uvicorn server in a separate terminal process
    uvicorn.run(app, host="127.0.0.1", port=8001)
