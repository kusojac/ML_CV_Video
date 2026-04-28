import os

def get_allowed_origins():
    origins = os.environ.get("ALLOWED_ORIGINS")
    if origins:
        return [origin.strip() for origin in origins.split(",")]
    return ["http://127.0.0.1:8001"]
