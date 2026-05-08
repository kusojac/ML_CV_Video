
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
