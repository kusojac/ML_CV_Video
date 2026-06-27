from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

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
