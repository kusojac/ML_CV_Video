## 2025-04-28 - Overly Permissive CORS Configuration
**Vulnerability:** The backend API allowed CORS requests from any origin (`allow_origins=["*"]`) which can lead to unauthorized access and data exposure if sensitive endpoints are present.
**Learning:** Overly permissive CORS is an easy oversight during prototyping that can be carried over into production, potentially exposing APIs to malicious sites.
**Prevention:** Implement an environment variable-based approach (e.g. `ALLOWED_ORIGINS`) to dynamically load allowed origins, falling back to a safe default.
