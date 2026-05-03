## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.

## 2024-05-03 - Deferring Expensive Numpy Operations in YOLO Postprocessing
**Learning:** In backend computer vision pipelines, computing operations like `np.argmax` on thousands of YOLO anchor boxes (e.g., 8400) is highly inefficient when most of those boxes will be discarded. The backend YOLO pipeline processes thousands of anchor boxes per frame, and running `np.argmax` on all of them was a significant bottleneck.
**Action:** Always filter by confidence threshold *before* performing expensive row-wise operations like `np.argmax` on model outputs. Defer the heavy computation only to the subset of anchor boxes that pass the threshold.
