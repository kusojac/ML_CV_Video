import os

def get_allowed_origins():
    """Returns a list of allowed CORS origins from environment variable or defaults."""
    default_origins = "http://localhost:8001,http://127.0.0.1:8001,http://localhost:8000,http://127.0.0.1:8000"
    allowed_origins_env = os.getenv("ALLOWED_ORIGINS", default_origins)
    return [origin.strip() for origin in allowed_origins_env.split(",") if origin.strip()]
