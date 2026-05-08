import warnings
warnings.filterwarnings("ignore", category=UserWarning, module="google.protobuf")
import json
import time
import asyncio
import os
import uuid
from typing import Dict, Any
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
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

# Persistent job state
job_store = JobStore(os.path.join(os.path.dirname(__file__), "jobs.db"))

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

def validate_safe_path(file_path: str) -> str:
    """Validates that the given path does not contain directory traversal characters."""
    if ".." in file_path:
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
        with open(json_path, 'w') as f:
            json.dump(result, f, indent=4)
            
        job_store.update_job(job_id, {
            "status": "completed",
            "progress": 1.0,
            "result": result,
            "json_path": json_path
        })
    except Exception as e:
        job_store.update_job(job_id, {
            "status": "error",
            "error": str(e)
        })


@app.post("/analyze")
async def analyze_video(request: AnalyzeRequest, background_tasks: BackgroundTasks):
    safe_video_path = validate_safe_path(request.video_path)
    if not os.path.exists(safe_video_path):
        raise HTTPException(status_code=404, detail="Video file not found.")

    json_path = get_json_path(safe_video_path)
    
    # If already processed, return it immediately
    if os.path.exists(json_path):
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
async def get_job_status(job_id: str):
    job = await asyncio.to_thread(job_store.get_job, job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    return job


@app.get("/ping")
async def ping():
    return {"status": "ok"}


@app.get("/results")
async def get_results(video_path: str):
    validate_safe_path(video_path)
    json_path = get_json_path(video_path)

    def load_json():
        if not os.path.exists(json_path):
            return None
        with open(json_path, 'r') as f:
            return json.load(f)

    data = await asyncio.to_thread(load_json)
    if data is None:
        raise HTTPException(status_code=404, detail="Analysis results not found.")
    
    return data


@app.post("/update_action")
async def update_action(req: UpdateActionRequest):
    validate_safe_path(req.video_path)
    json_path = get_json_path(req.video_path)

    def perform_update():
        if not os.path.exists(json_path):
            return "NOT_FOUND"

        with open(json_path, 'r') as f:
            data = json.load(f)
            
        found = False
        for action in data.get("actions", []):
            if action.get("id") == req.action_id:
                action["type"] = req.new_type
                action["start_ms"] = req.new_start_ms
                action["end_ms"] = req.new_end_ms
                found = True
                break

        if not found:
            return "ACTION_NOT_FOUND"

        with open(json_path, 'w') as f:
            json.dump(data, f, indent=4)
        return "SUCCESS"

    result = await asyncio.to_thread(perform_update)
    if result == "NOT_FOUND":
        raise HTTPException(status_code=404, detail="Analysis results not found.")
    elif result == "ACTION_NOT_FOUND":
        raise HTTPException(status_code=404, detail="Action ID not found.")
        
    return {"status": "success"}

if __name__ == "__main__":
    import uvicorn
    # Make sure to run the uvicorn server in a separate terminal process
    uvicorn.run(app, host="0.0.0.0", port=8000)
