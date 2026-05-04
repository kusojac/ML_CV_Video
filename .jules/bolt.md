## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.

## 2023-10-27 - Remove synchronous file system checks in FastAPI endpoints
**Learning:** Using synchronous `os.path.exists()` followed by file opening introduces a TOCTOU (Time-of-Check to Time-of-Use) vulnerability and redundant I/O operations, which blocks the event loop in async FastAPI endpoints.
**Action:** Apply the EAFP (Easier to Ask for Forgiveness than Permission) principle. Directly attempt to `open()` the file and handle `FileNotFoundError` within a `try...except` block, ensuring faster execution and atomic file access.
