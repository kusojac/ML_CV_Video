## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.

## 2024-05-15 - Defer Expensive Operations in Object Detection Pipelines
**Learning:** Found a performance bottleneck in `VolleyballApp/backend/frame_utilities.py` where `np.argmax(class_scores, axis=1)` was executed on all anchor boxes (thousands per frame) before filtering by confidence threshold.
**Action:** When filtering a large number of predictions based on a confidence threshold, apply the threshold mask *before* running expensive operations like `np.argmax` on the remaining high-confidence candidates to significantly improve per-frame processing speed.
