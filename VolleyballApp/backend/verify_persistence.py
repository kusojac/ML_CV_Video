import sys
import os
import uuid
import json

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), "VolleyballApp/backend"))

from database import JobStore

def test_job_store():
    print("Testing JobStore...")
    db_path = "test_jobs.db"
    if os.path.exists(db_path):
        os.remove(db_path)

    store = JobStore(db_path)
    job_id = str(uuid.uuid4())

    # Test set_job
    store.set_job(job_id, {"status": "pending", "progress": 0.0, "video_path": "test.mp4"})
    job = store.get_job(job_id)
    assert job["status"] == "pending"
    assert job["progress"] == 0.0
    assert job["video_path"] == "test.mp4"

    # Test update_job
    store.update_job(job_id, {"status": "completed", "progress": 1.0, "result": {"actions": []}})
    job = store.get_job(job_id)
    assert job["status"] == "completed"
    assert job["progress"] == 1.0
    assert job["result"] == {"actions": []}

    # Test persistence across instances
    store2 = JobStore(db_path)
    job2 = store2.get_job(job_id)
    assert job2["status"] == "completed"

    # Test SQL injection prevention/Allowed columns
    store.update_job(job_id, {"status": "updated", "invalid_col": "should_be_ignored"})
    job3 = store.get_job(job_id)
    assert job3["status"] == "updated"
    assert "invalid_col" not in job3

    print("JobStore tests passed!")
    if os.path.exists(db_path):
        os.remove(db_path)

if __name__ == "__main__":
    try:
        test_job_store()
    except Exception as e:
        print(f"Tests failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
