from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_analyze_path_traversal():
    response = client.post("/analyze", json={"video_path": "../../../etc/passwd"})
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid path provided."}

def test_results_path_traversal():
    response = client.get("/results?video_path=../../../etc/passwd")
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid path provided."}

def test_update_action_path_traversal():
    response = client.post("/update_action", json={
        "video_path": "../../../etc/passwd",
        "action_id": "test",
        "new_type": "test",
        "new_start_ms": 0.0,
        "new_end_ms": 1.0
    })
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid path provided."}

def test_absolute_path_blocked():
    # Should return 400 to prevent absolute path access
    response = client.post("/analyze", json={"video_path": "/var/log/syslog"})
    assert response.status_code == 400
    assert response.json() == {"detail": "Invalid path provided."}

def test_analyze_dos():
    long_path = "a" * 5000
    response = client.post("/analyze", json={"video_path": long_path})
    assert response.status_code == 422 # Unprocessable Entity

def test_results_dos():
    long_path = "a" * 5000
    response = client.get(f"/results?video_path={long_path}")
    assert response.status_code == 422 # Unprocessable Entity

def test_security_headers():
    response = client.get("/ping")
    assert response.status_code == 200
    assert response.headers.get("X-Content-Type-Options") == "nosniff"
    assert response.headers.get("X-Frame-Options") == "DENY"
    assert response.headers.get("Strict-Transport-Security") == "max-age=31536000; includeSubDomains"
    assert response.headers.get("X-XSS-Protection") == "1; mode=block"
    assert response.headers.get("Content-Security-Policy") == "default-src 'none'; frame-ancestors 'none'"

def test_security_headers_docs():
    response = client.get("/docs")
    assert response.status_code == 200
    assert "Content-Security-Policy" not in response.headers

    response = client.get("/redoc")
    assert response.status_code == 200
    assert "Content-Security-Policy" not in response.headers

    response = client.get("/openapi.json")
    assert response.status_code == 200
    assert "Content-Security-Policy" not in response.headers

def test_analyze_concurrency_dos():
    from main import analysis_jobs, MAX_CONCURRENT_JOBS
    original_jobs = analysis_jobs.copy()
    try:
        analysis_jobs.clear()
        for i in range(MAX_CONCURRENT_JOBS):
            analysis_jobs[f"fake_job_{i}"] = {"status": "processing"}
        response = client.post("/analyze", json={"video_path": "test.mp4"})
        assert response.status_code == 429
        assert response.json() == {"detail": "Too many active analysis jobs. Please try again later."}
    finally:
        analysis_jobs.clear()
        analysis_jobs.update(original_jobs)
