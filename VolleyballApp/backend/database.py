import sqlite3
import json
from typing import Dict, Any, Optional

class JobStore:
    def __init__(self, db_path: str = "jobs.db"):
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        conn = sqlite3.connect(self.db_path)
        try:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS jobs (
                    job_id TEXT PRIMARY KEY,
                    status TEXT,
                    progress REAL,
                    video_path TEXT,
                    eta_seconds INTEGER,
                    result TEXT,
                    json_path TEXT,
                    error TEXT
                )
            """)
            conn.commit()
        finally:
            conn.close()

    def set_job(self, job_id: str, job_data: Dict[str, Any]):
        conn = sqlite3.connect(self.db_path)
        try:
            conn.execute(
                "INSERT OR REPLACE INTO jobs (job_id, status, progress, video_path) VALUES (?, ?, ?, ?)",
                (job_id, job_data.get("status"), job_data.get("progress"), job_data.get("video_path"))
            )
            conn.commit()
        finally:
            conn.close()

    def update_job(self, job_id: str, updates: Dict[str, Any]):
        if not updates:
            return

        allowed_columns = {"status", "progress", "video_path", "eta_seconds", "result", "json_path", "error"}

        conn = sqlite3.connect(self.db_path)
        try:
            fields = []
            values = []
            for key, value in updates.items():
                if key not in allowed_columns:
                    continue
                fields.append(f"{key} = ?")
                if key == "result" and value is not None:
                    values.append(json.dumps(value))
                else:
                    values.append(value)

            if not fields:
                return

            values.append(job_id)
            query = f"UPDATE jobs SET {', '.join(fields)} WHERE job_id = ?"
            conn.execute(query, tuple(values))
            conn.commit()
        finally:
            conn.close()

    def get_job(self, job_id: str) -> Optional[Dict[str, Any]]:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            cursor = conn.execute("SELECT * FROM jobs WHERE job_id = ?", (job_id,))
            row = cursor.fetchone()
            if row:
                job = dict(row)
                del job["job_id"]
                if job.get("result"):
                    job["result"] = json.loads(job["result"])
                return {k: v for k, v in job.items() if v is not None}
            return None
        finally:
            conn.close()
