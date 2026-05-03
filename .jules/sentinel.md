## 2024-05-03 - Path Traversal Prevention
**Vulnerability:** Fast API endpoints accepting direct file paths allowed arbitrary file access via directory traversal (e.g. `../`).
**Learning:** Local desktop apps often require absolute paths, but relative traversals must still be explicitly blocked to prevent arbitrary file read/write vulnerabilities.
**Prevention:** Implement and enforce a `secure_path` utility that strictly blocks any path containing `..`.
