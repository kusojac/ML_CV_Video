import warnings
warnings.filterwarnings("ignore", category=UserWarning, module="google.protobuf")
import json
import time

import os
import uuid
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
        with open(json_path, 'w') as f:
            json.dump(result, f, indent=4)
            
        analysis_jobs[job_id]["status"] = "completed"
        analysis_jobs[job_id]["progress"] = 1.0
        analysis_jobs[job_id]["result"] = result
        analysis_jobs[job_id]["json_path"] = json_path
    except Exception as e:
        analysis_jobs[job_id]["status"] = "error"
        analysis_jobs[job_id]["error"] = str(e)


@app.post("/analyze")
async def analyze_video(request: AnalyzeRequest, background_tasks: BackgroundTasks):
    if not os.path.exists(request.video_path):
        raise HTTPException(status_code=404, detail="Video file not found.")

    json_path = get_json_path(request.video_path)
    
    # If already processed, return it immediately
    if os.path.exists(json_path):
        return {"status": "completed", "json_path": json_path}

    job_id = str(uuid.uuid4())
    analysis_jobs[job_id] = {
        "status": "pending",
        "progress": 0.0,
        "video_path": request.video_path
    }
    background_tasks.add_task(process_video_task, job_id, request.video_path)
    return {"job_id": job_id, "status": "pending"}


@app.get("/job/{job_id}")
async def get_job_status(job_id: str):
    if job_id not in analysis_jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    return analysis_jobs[job_id]


@app.get("/results")
async def get_results(video_path: str):
    json_path = get_json_path(video_path)
    if not os.path.exists(json_path):
        raise HTTPException(status_code=404, detail="Analysis results not found.")
    
    with open(json_path, 'r') as f:
        data = json.load(f)
    return data


@app.post("/update_action")
async def update_action(req: UpdateActionRequest):
    json_path = get_json_path(req.video_path)
    if not os.path.exists(json_path):
        raise HTTPException(status_code=404, detail="Analysis results not found.")
        
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
        raise HTTPException(status_code=404, detail="Action ID not found.")
        
    with open(json_path, 'w') as f:
        json.dump(data, f, indent=4)
        
    return {"status": "success"}

if __name__ == "__main__":
    import uvicorn
    # Make sure to run the uvicorn server in a separate terminal process
    uvicorn.run(app, host="0.0.0.0", port=8000)
