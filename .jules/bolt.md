## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.
## 2026-04-28 - FastAPI Synchronous File IO Threadpool Execution

**Learning:** When performing blocking synchronous file I/O (like reading/writing large JSON files) within FastAPI endpoints, using `async def` without `await` blocks the main asyncio event loop, causing severe latency for concurrent requests. Defining the endpoints with `def` allows Starlette to automatically route them to an external threadpool, preserving asynchronous performance. However, shifting to a threadpool introduces concurrency, meaning data structures accessed from these endpoints (like shared files) require thread safety mechanisms like `threading.Lock()` to prevent race conditions and data corruption.

**Action:** For heavy, synchronous IO-bound operations in FastAPI, define the endpoint function with `def` rather than `async def` and ensure shared resources are protected with threading locks.
