import os

# Define allowed origins for CORS.
# For local desktop apps, restrict this to local origins to prevent malicious websites
# from triggering local backend actions.
allowed_origins_env = os.environ.get("ALLOWED_ORIGINS", "http://localhost:8001,http://127.0.0.1:8001")
ALLOWED_ORIGINS = [origin.strip() for origin in allowed_origins_env.split(",") if origin.strip()]
