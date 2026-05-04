## 2024-04-29 - [Fix overly permissive CORS configuration]
**Vulnerability:** The FastAPI backend had its CORS middleware configured with `allow_origins=["*"]`, meaning it would accept cross-origin requests from any domain.
**Learning:** In a local desktop architecture (like this Flutter app talking to a local Python backend), having an open CORS policy allows any malicious website a user visits to send requests to the local backend service (e.g., `http://localhost:8000`) and trigger local actions or access local files.
**Prevention:** Use an explicit list of allowed local origins (e.g., `http://localhost:8001`, `http://127.0.0.1:8001`) via environment variables rather than a wildcard `*`.
