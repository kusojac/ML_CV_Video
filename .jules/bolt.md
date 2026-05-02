## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.

## 2024-05-02 - Deferring Expensive Numpy Operations in YOLO Post-processing
**Learning:** Found an instance in `VolleyballApp/backend/frame_utilities.py` where `np.argmax` was being called on the entire raw output array from a YOLO model (e.g., thousands of anchor boxes) before applying the confidence threshold filter. This operation is expensive and unnecessary for bounding boxes that will be discarded.
**Action:** In object detection post-processing pipelines handling many anchor boxes, defer expensive array operations like `np.argmax` until *after* filtering by the initial confidence threshold mask to process significantly fewer elements.
