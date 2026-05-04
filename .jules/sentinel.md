## 2024-05-04 - Fix Path Traversal Vulnerability in Video Processing Endpoints
**Vulnerability:** The backend endpoints `/analyze`, `/results`, and `/update_action` accepted a `video_path` parameter from the user directly and passed it to `os.path.exists` and `open()` without any validation. Because it's a local desktop app and allows absolute local file paths, an attacker could use relative path traversal (`..`) to access arbitrary files on the local file system.
**Learning:** Even internal or local desktop APIs can be vulnerable to directory traversal if they allow absolute paths and do not sanitize inputs containing `..`.
**Prevention:** Implement a `secure_path` helper function that blocks input containing `..` and apply it to all endpoints receiving user-provided file paths.
