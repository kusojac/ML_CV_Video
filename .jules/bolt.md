## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.

## 2024-05-04 - Backend API Update Action Optimization
**Learning:** Repetitive file reading, parsing, and $O(N)$ linear searches on large JSON structures during API requests (`update_action`) cause severe performance bottlenecks, taking >1.6 seconds for massive files. A global cache with memory lookup dictionaries provides $O(1)$ lookup time, lowering the request duration substantially (by >90% internally). However, unbounded caches in single-worker backends are susceptible to Out-Of-Memory leaks over time and inconsistent state in multi-worker environments.
**Action:** When implementing an in-memory cache, pair it with size-bound limitations (e.g., LRU cache) and state-sync mechanisms if moving to a distributed/multi-worker architecture.
