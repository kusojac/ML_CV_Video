
## 2025-05-04 - Fix Insecure Deserialization Vulnerability
**Vulnerability:** The backend loaded a Random Forest classifier using `pickle.load()` (`model.p`), exposing the system to arbitrary code execution (RCE) via insecure deserialization.
**Learning:** Machine learning models serialized using Python's native `pickle` format are unsafe to deserialize, especially in production environments where malicious actors could manipulate the file.
**Prevention:** Avoid `pickle` entirely for model storage. Always serialize machine learning models into safe representations like ONNX (via `skl2onnx`) and load them using secure engines like `onnxruntime`.
## 2024-05-04 - Fix Path Traversal Vulnerability in Video Processing Endpoints
**Vulnerability:** The backend endpoints `/analyze`, `/results`, and `/update_action` accepted a `video_path` parameter from the user directly and passed it to `os.path.exists` and `open()` without any validation. Because it's a local desktop app and allows absolute local file paths, an attacker could use relative path traversal (`..`) to access arbitrary files on the local file system.
**Learning:** Even internal or local desktop APIs can be vulnerable to directory traversal if they allow absolute paths and do not sanitize inputs containing `..`.
**Prevention:** Implement a `secure_path` helper function that blocks input containing `..` and apply it to all endpoints receiving user-provided file paths.
## 2024-05-02 - Fix Path Traversal Vulnerability in Video Processing Endpoints
**Vulnerability:** The API endpoints (`/analyze`, `/results`, `/update_action`) previously accepted unsanitized file paths via `video_path` parameter, allowing arbitrary path traversal using relative paths (`..`). This could expose system files or other sensitive JSON data.
**Learning:** In desktop-focused backends where absolute local file paths are permitted for UX reasons, missing basic constraints on relative directory traversal (`..`) can result in silent critical vulnerabilities, especially when generating paths (e.g., `get_json_path`).
**Prevention:** Always sanitize absolute path inputs by explicitly verifying and disallowing relative directory traversals (`..`) via a shared validation helper like `secure_path()` before they interact with the file system.
## 2025-02-14 - Directory Traversal Vulnerability in Video Path
**Vulnerability:** Endpoints `/analyze`, `/results`, and `/update_action` accept arbitrary user-provided file paths via the `video_path` parameter and performed file system operations directly using `os.path.exists` and `open`. Although this desktop app needs to support absolute paths, relative path traversal (`..`) wasn't explicitly blocked, potentially allowing access to unauthorized files.
**Learning:** Because the app interacts with local file systems via API parameters, relying on client-side constraints is insufficient. The backend must enforce boundaries even when dealing with absolute paths intended for local desktop interaction.
**Prevention:** Implement a `secure_path` helper function that blocks requests containing `..` in the `path`, returning an HTTP 400 response. This function must be consistently called at the beginning of all endpoints handling file paths.
## 2025-05-18 - [Path Traversal in Video Processing Endpoints]
**Vulnerability:** The `/analyze`, `/results`, and `/update_action` endpoints accepted `video_path` as unsanitized user input and passed it directly to `os.path.exists` and `open()`. This allowed path traversal to read arbitrary files via inputs like `../../../etc/passwd`.
**Learning:** For a local Desktop + API architecture, we cannot blindly block all absolute paths (e.g. `/` or `C:\`) because the frontend user is expected to supply absolute paths to their local video files. The security context differs from a traditional web application escaping a webroot.
**Prevention:** Validation must explicitly target directory traversal characters like `..` while preserving the application's required functionality of accessing user-specified local absolute paths. Always evaluate the architectural context before applying blanket path restrictions.
## 2024-04-29 - [Fix overly permissive CORS configuration]
**Vulnerability:** The FastAPI backend had its CORS middleware configured with `allow_origins=["*"]`, meaning it would accept cross-origin requests from any domain.
**Learning:** In a local desktop architecture (like this Flutter app talking to a local Python backend), having an open CORS policy allows any malicious website a user visits to send requests to the local backend service (e.g., `http://localhost:8000`) and trigger local actions or access local files.
**Prevention:** Use an explicit list of allowed local origins (e.g., `http://localhost:8001`, `http://127.0.0.1:8001`) via environment variables rather than a wildcard `*`.

## 2025-05-14 - Fix Server Bind to All Interfaces
**Vulnerability:** The FastAPI backend was configured to bind to "0.0.0.0", exposing the local API to the entire network.
**Learning:** For local desktop applications with a companion backend, binding to "0.0.0.0" is a security risk as it allows any device on the network to interact with the backend, which might have access to local files or perform sensitive actions.
**Prevention:** Always bind to "127.0.0.1" for local-only services. Additionally, ensure the port configuration is consistent across the backend code, documentation, and frontend service to avoid connectivity issues while hardening the service.
## 2025-05-09 - [Fix unhandled JSONDecodeError exposing stack trace]
**Vulnerability:** FastAPIs internal behavior exposed internal application stacks if endpoints loaded corrupted or malformed internal JSON files, which is a potential source of internal architecture data leakage for bad actors parsing stack traces.
**Learning:** `json.load()` throws `json.JSONDecodeError` for invalid JSON payloads. Without specific handlers caching or trapping this, generic exceptions bubble up exposing verbose system internals.
**Prevention:** Make sure `json.load` explicitly handles `json.JSONDecodeError` using `try-except` blocks and replaces it with standard `HTTPException` displaying sanitized or minimal error messages to clients without exposing the application runtime stack.

## 2024-05-09 - Insecure Deserialization via pickle.load
**Vulnerability:** The backend `VolleyballAnalyticsEngine` previously initialized a machine learning model (`model.p`) using `pickle.load`. This exposed the application to remote code execution (RCE) via insecure deserialization, as a malicious actor could replace `model.p` with a crafted payload.
**Learning:** `pickle.load` executes arbitrary code contained within the serialized payload during deserialization. It is fundamentally unsafe to use `pickle` for loading machine learning models (or any data) from untrusted or easily accessible locations.
**Prevention:** Avoid `pickle` entirely for model serialization. Always convert machine learning models into safe, standardized formats like ONNX (`.onnx`) using tools like `skl2onnx`, and load them using secure engines such as `onnxruntime.InferenceSession`.
## 2025-05-18 - Fix Null Byte Injection in File Paths
**Vulnerability:** The `secure_path` function in `main.py` checked for directory traversal (`..`) but failed to check for null bytes (`\x00`). When a null byte was passed to file system operations (like `open`, `os.path.exists`, or `cv2.VideoCapture`), it caused a `ValueError('embedded null byte')`.
**Learning:** Python's underlying C file system APIs reject strings containing null bytes. In a web API, if user input is not explicitly validated against `\x00`, this can lead to unhandled 500 Internal Server Errors, application crashes, or bypasses of file extension checks (e.g., `file.mp4\x00.exe`).
**Prevention:** Always validate user-provided file paths against null bytes (`\x00`) in addition to directory traversal sequences, returning a 400 Bad Request to fail securely.

## 2026-05-12 - Insecure Deserialization via pickle in Conversion Scripts
**Vulnerability:** The model conversion script (`convert.py`) used `pickle.load` directly to load the `model.p` file. This exposes the developer environment/build pipeline to Remote Code Execution (RCE) via insecure deserialization, as a malicious actor could replace the input `.p` file.
**Learning:** Even one-off conversion scripts that process `.p` or `.pkl` files are vulnerable if they blindly trust the payload. The risk isn't just in production APIs but also in ML engineering pipelines.
**Prevention:** For model conversion scripts where `pickle` input is unavoidable, mitigate Remote Code Execution (RCE) risks by implementing a `RestrictedUnpickler` that overrides `find_class` to strictly whitelist only essential scikit-learn/numpy namespaces and safe primitive built-in types (e.g., `dict`, `list`, `int`). Explicitly avoid whitelisting entire modules like `builtins` or dangerous functions like `eval` and `getattr`.
## 2025-05-13 - Add Path Max Length Validation to Prevent DoS
**Vulnerability:** The `/analyze`, `/results`, and `/update_action` endpoints accepted arbitrarily long strings for `video_path` and `action_id` without validation. Very long strings caused an unhandled `OSError` deeper in the call stack due to OS file name length limits, bypassing our structured HTTP 400 paths and crashing threads, representing a DoS vector.
**Learning:** Pydantic `BaseModel` default `str` fields and FastAPI query string parameters do not enforce maximum lengths automatically. Large payloads are processed by the framework and event loop before custom logic.
**Prevention:** Use `pydantic.Field(..., max_length=1000)` and `fastapi.Query(..., max_length=1000)` to enforce strict bounds on unbounded inputs at the framework level, guaranteeing a graceful 422 Unprocessable Entity response before processing.
\n## 2026-05-14 - Prevent DoS with Input Length Limits\n**Vulnerability:** Missing input length limits on FastAPI endpoints allowing potentially unlimited string payloads.\n**Learning:** In FastAPI apps, Pydantic fields and route parameters (Query/Path) need explicit `max_length` attributes to defend against memory exhaustion/DoS attacks.\n**Prevention:** Use `pydantic.Field(max_length=...)` and `fastapi.Query(max_length=...)` / `fastapi.Path(max_length=...)` for all user-provided strings.
## 2025-05-18 - [Fix DoS Vulnerability via Memory Exhaustion in API Input Lengths]
**Vulnerability:** The FastAPI endpoints endpoints (`/analyze`, `/results`, `/update_action`, `/job/{job_id}`) accepted arbitrary string inputs (e.g. `video_path`, `action_id`) through Pydantic models and query/path parameters without any `max_length` bounds. An attacker could exploit this by sending requests with exceptionally large strings, forcing the backend to allocate large amounts of memory and crash due to memory exhaustion (Denial of Service).
**Learning:** By default, Pydantic `str` types and FastAPI string parameters have unbounded lengths. This poses a silent DoS risk in API boundaries parsing unbounded incoming JSON and URL requests.
**Prevention:** Always enforce strict `max_length` constraints on string inputs using `pydantic.Field` for model attributes and `fastapi.Query`/`fastapi.Path` for route parameters to limit memory allocation.

## 2026-05-15 - Missing Security Headers in FastAPI Response
**Vulnerability:** The FastAPI backend did not include standard security headers in its HTTP responses. This leaves API endpoints vulnerable to several web-based attacks (e.g., MIME sniffing, clickjacking, XSS), which reduces defense-in-depth even for local desktop or basic APIs.
**Learning:** Default framework configurations (like bare FastAPI) do not typically add fundamental security headers automatically. Relying solely on CORS middleware leaves gaps in defense-in-depth protection for other common browser-based attack vectors.
**Prevention:** Implement a global middleware that automatically injects fundamental security headers (`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security`, and `X-XSS-Protection`) to enforce defense-in-depth across all endpoints.
## 2026-05-17 - Fix Information Leakage in Background Task Errors
**Vulnerability:** The `process_video_task` in FastAPI previously captured raw exception objects from the engine and returned them verbatim via the `/job/{job_id}` unauthenticated status endpoint. This allowed attackers to induce failures and extract internal application details like paths, ML engine structures, or stack traces.
**Learning:** In asynchronous or background task endpoints, returning unhandled exception strings directly to the client is a form of information leakage. These APIs should only return sanitized state.
**Prevention:** Catch expected or unexpected exceptions in background threads, log the actual raw error to a secure internal log (using `logging.error`), and mutate the job state with a generic, safe string like 'An internal error occurred'.

## 2024-05-04 - Insecure Deserialization via pickle.load

**Vulnerability:** The application used `pickle.load` to load a Random Forest model (`model.p`) in `VolleyballApp/backend/engine.py`. This is an insecure deserialization vulnerability, as an attacker who can modify or replace the `model.p` file could execute arbitrary Python code when the backend server starts and instantiates the `VolleyballAnalyticsEngine` class.

**Learning:** When loading machine learning models from disk, especially in an environment where the model files might be externally supplied or altered, using format-specific binary loaders like `onnxruntime` or safer serialization like `joblib` (with `safe_load=True` if applicable) should always be preferred over Python's built-in `pickle`.

**Prevention:** Avoid `pickle.load` for external or untrusted data. Standardize on secure model representation formats like ONNX, which separates the model architecture and weights from general-purpose execution context, eliminating the code execution risk inherent to unpickling.

## 2026-05-22 - Add Security Headers Middleware
**Vulnerability:** The FastAPI backend lacked basic HTTP security headers (like X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security, and X-XSS-Protection).
**Learning:** Relying solely on CORS is insufficient for defense-in-depth against client-side attacks (e.g. MIME sniffing, clickjacking).
**Prevention:** Implement an  to unconditionally inject standard security headers into all API responses.

## 2026-05-22 - Add Security Headers Middleware
**Vulnerability:** The FastAPI backend lacked basic HTTP security headers (like X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security, and X-XSS-Protection).
**Learning:** Relying solely on CORS is insufficient for defense-in-depth against client-side attacks (e.g. MIME sniffing, clickjacking).
**Prevention:** Implement an `@app.middleware("http")` to unconditionally inject standard security headers into all API responses.
## 2026-05-21 - Add Defense-in-Depth HTTP Security Headers
**Vulnerability:** The application was missing basic standard HTTP security headers across its responses.
**Learning:** Default framework configurations (like bare FastAPI) do not typically add fundamental security headers automatically. Relying solely on CORS middleware leaves gaps in defense-in-depth protection for other common browser-based attack vectors.
**Prevention:** Implement a global HTTP middleware that automatically injects fundamental security headers (`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security`, and `X-XSS-Protection`) to enforce defense-in-depth across all endpoints.

## $(date +%Y-%m-%d) - Denial of Service via Missing Length Limits on Optional Pydantic Fields
**Vulnerability:** Optional string fields in Pydantic models (e.g., `new_player_id: Optional[str]`) were missing `max_length` constraints, allowing attackers to send arbitrarily large payloads that could cause memory exhaustion (DoS).
**Learning:** Even if a field is `Optional`, Pydantic will still parse and allocate memory for it if provided in the payload. Missing length limits on any user-provided string field is a Denial of Service vector.
**Prevention:** Ensure all string inputs in Pydantic models, including `Optional` ones, enforce strict `max_length` constraints using `pydantic.Field(default=None, max_length=X)`.
## 2026-05-23 - Prevent DoS via Memory Exhaustion in Optional Fields
**Vulnerability:** The `/update_action` endpoint in FastAPI accepted arbitrarily large string payloads for the `new_player_id` and `new_active_focus_id` optional fields. Without length bounds, attackers could exploit this by sending requests with exceptionally large strings, exhausting server memory and causing a Denial of Service (DoS) attack.
**Learning:** By default, Pydantic `Optional[str]` fields do not enforce any limits on the length of string input unless explicitly specified using `pydantic.Field(..., max_length=...)`. Because FastApi parses incoming request JSON payloads directly, unbounded string parameters pose a memory exhaustion risk at the API boundary before any custom application logic runs.
**Prevention:** Always specify strict boundaries such as `max_length` using `pydantic.Field` on string parameters within Pydantic models—including `Optional[str]` fields. Doing so guarantees a 422 Unprocessable Entity gracefully limits payload size at the framework layer.
