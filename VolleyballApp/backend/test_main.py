import os
import sys
from unittest.mock import patch
from fastapi.testclient import TestClient

# Add current dir to sys.path so we can import modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import get_allowed_origins
from main import app

client = TestClient(app)

def test_get_allowed_origins_default():
    # Ensure ALLOWED_ORIGINS is not set
    with patch.dict(os.environ, {}, clear=True):
        origins = get_allowed_origins()
        assert origins == ["http://127.0.0.1:8001"]

def test_get_allowed_origins_custom():
    # Ensure ALLOWED_ORIGINS is set
    with patch.dict(os.environ, {"ALLOWED_ORIGINS": "http://localhost:3000, https://example.com"}):
        origins = get_allowed_origins()
        assert origins == ["http://localhost:3000", "https://example.com"]

def test_cors_headers_rejected_origin():
    # Make a request with an origin that shouldn't be allowed
    response = client.options(
        "/analyze",
        headers={"Origin": "http://malicious.com", "Access-Control-Request-Method": "POST"}
    )
    # The response should not contain the Access-Control-Allow-Origin header
    # for the malicious origin, or it should be missing entirely depending on FastAPI's
    # CORS middleware behavior.
    assert "access-control-allow-origin" not in response.headers or response.headers["access-control-allow-origin"] != "http://malicious.com"

def test_cors_headers_allowed_origin():
    # By default, "http://127.0.0.1:8001" is allowed
    response = client.options(
        "/analyze",
        headers={"Origin": "http://127.0.0.1:8001", "Access-Control-Request-Method": "POST"}
    )
    assert response.headers.get("access-control-allow-origin") == "http://127.0.0.1:8001"
