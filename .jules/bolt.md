## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.

## 2024-05-18 - Deferring Expensive Array Operations in YOLO Post-processing
**Learning:** Found an instance in `VolleyballApp/backend/frame_utilities.py` where `np.argmax` was being called on thousands of YOLO output anchor boxes before applying the confidence threshold filter. This is a common bottleneck in object detection post-processing since the majority of anchors have very low confidence scores.
**Action:** Always filter YOLO anchor boxes based on objectness or max class score before calculating specific class assignments via `np.argmax` to avoid unnecessary expensive operations on irrelevant data.
