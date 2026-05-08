## 2024-04-30 - Deferred np.argmax in YOLO Post-Processing
**Learning:** In the backend YOLO post-processing pipeline (`frame_utilities.py`), computing `np.argmax` over thousands of anchor boxes (e.g., 8400) for class IDs is extremely expensive and causes a severe performance bottleneck.
**Action:** Always filter the confidence scores against a threshold first to generate a subset, and then defer expensive NumPy matrix operations like `np.argmax` until after filtering. This drastically reduces the workload and significantly improves post-processing performance.
## 2024-04-28 - Redundant Image Preprocessing in CV Pipeline
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where the exact same preprocessing function (`preprocess_yolo_input`) was called twice on the same frame (once for ball detection and once for person detection) within the per-frame processing loop. In computer vision tasks, image resizing and array normalization are expensive.
**Action:** When working with multiple inference models that expect the same input format in a hot loop, assign the preprocessed input to a variable and reuse it across multiple model runs.

## 2024-05-18 - Deferring Expensive Array Operations in YOLO Post-processing
**Learning:** Found an instance in `VolleyballApp/backend/frame_utilities.py` where `np.argmax` was being called on thousands of YOLO output anchor boxes before applying the confidence threshold filter. This is a common bottleneck in object detection post-processing since the majority of anchors have very low confidence scores.
**Action:** Always filter YOLO anchor boxes based on objectness or max class score before calculating specific class assignments via `np.argmax` to avoid unnecessary expensive operations on irrelevant data.
## 2024-05-03 - Deferring Expensive Numpy Operations in YOLO Postprocessing
**Learning:** In backend computer vision pipelines, computing operations like `np.argmax` on thousands of YOLO anchor boxes (e.g., 8400) is highly inefficient when most of those boxes will be discarded. The backend YOLO pipeline processes thousands of anchor boxes per frame, and running `np.argmax` on all of them was a significant bottleneck.
**Action:** Always filter by confidence threshold *before* performing expensive row-wise operations like `np.argmax` on model outputs. Defer the heavy computation only to the subset of anchor boxes that pass the threshold.
## 2024-05-02 - Deferring Expensive Numpy Operations in YOLO Post-processing
**Learning:** Found an instance in `VolleyballApp/backend/frame_utilities.py` where `np.argmax` was being called on the entire raw output array from a YOLO model (e.g., thousands of anchor boxes) before applying the confidence threshold filter. This operation is expensive and unnecessary for bounding boxes that will be discarded.
**Action:** In object detection post-processing pipelines handling many anchor boxes, defer expensive array operations like `np.argmax` until *after* filtering by the initial confidence threshold mask to process significantly fewer elements.
## 2024-05-15 - Defer Expensive Operations in Object Detection Pipelines
**Learning:** Found a performance bottleneck in `VolleyballApp/backend/frame_utilities.py` where `np.argmax(class_scores, axis=1)` was executed on all anchor boxes (thousands per frame) before filtering by confidence threshold.
**Action:** When filtering a large number of predictions based on a confidence threshold, apply the threshold mask *before* running expensive operations like `np.argmax` on the remaining high-confidence candidates to significantly improve per-frame processing speed.

## 2024-05-20 - Vectorized Minimum Distance Search in Inference Loops
**Learning:** Found an instance in `VolleyballApp/backend/engine.py` where a Python `for` loop was used to find the closest person detection to a ball detection using `get_distance_person_ball_np`. Iterating over detections in Python is a significant bottleneck compared to NumPy vectorization, especially when calculating Euclidean distances which often involve expensive `sqrt` calls.
**Action:** Always replace Python loops with NumPy vectorized operations (broadcasting) for spatial calculations. Use squared Euclidean distance (`dist_sq = (x1-x2)**2 + (y1-y2)**2`) for finding minimums/maximums to avoid redundant square root calculations. Use NumPy boolean indexing for filtering instead of list comprehensions.

## 2024-04-29 - [Optimization of YOLO post-processing pipeline]
**Learning:** Computing `np.argmax(class_scores, axis=1)` across all 8400 outputs of the COCO model before filtering out low-confidence boxes leads to significant unnecessary processing overhead. This was a critical bottleneck affecting the overall pipeline latency per frame.
**Action:** Defer calculating class IDs via `np.argmax` (and zero initialization for ball models) until after applying the `valid_mask = scores > conf_threshold`. This simple reordering dramatically cuts the computation time from thousands of boxes to a few dozen without altering the result.
