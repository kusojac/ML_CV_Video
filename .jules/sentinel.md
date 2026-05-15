
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
## 2025-05-08 - Unauthorized Network Exposure via 0.0.0.0
**Vulnerability:** The FastAPI backend using Uvicorn was configured to bind to all network interfaces (`0.0.0.0`), exposing the local desktop application's backend to the entire local network (or public network if not firewalled).
**Learning:** Local desktop applications typically only need to communicate between their local frontend and backend components. Binding to `0.0.0.0` unnecessarily expands the attack surface, potentially allowing anyone on the network to interact with the backend API.
**Prevention:** Always bind local application backends strictly to the loopback interface (`127.0.0.1` or `localhost`) unless external network access is an explicit and authenticated requirement.
## 2025-05-18 - [Fix insecure network binding exposing local backend]
**Vulnerability:** The FastAPI backend bound to `0.0.0.0` in `main.py` (`uvicorn.run(app, host="0.0.0.0", port=8000)`). Since this is a local desktop application with an unauthenticated API, binding to all interfaces exposed it to the entire local network, meaning any unauthorized device on the same network could access local data or trigger actions.
**Learning:** For desktop applications using local REST/RPC backends, blindly copying web server defaults (like binding to `0.0.0.0` or `*`) is extremely dangerous as it bypasses local boundaries.
**Prevention:** Always ensure local backend APIs explicitly bind to the loopback interface (`127.0.0.1` or `localhost`) unless intentionally serving a remote frontend.
## 2025-02-28 - Local Backend Bound to All Network Interfaces
**Vulnerability:** The FastAPI backend service was configured to bind to `0.0.0.0`, exposing the local desktop application's backend to the entire local network rather than just the host machine.
**Learning:** For local desktop applications, binding backend services to all interfaces (`0.0.0.0`) creates an unintended network attack surface, allowing anyone on the same network to potentially access the API endpoints and local files.
**Prevention:** Always bind local-only desktop backend services strictly to the loopback interface (`127.0.0.1`) to ensure they are only accessible from the host machine itself.

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
