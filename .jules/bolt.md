## 2024-04-30 - Deferred np.argmax in YOLO Post-Processing
**Learning:** In the backend YOLO post-processing pipeline (`frame_utilities.py`), computing `np.argmax` over thousands of anchor boxes (e.g., 8400) for class IDs is extremely expensive and causes a severe performance bottleneck.
**Action:** Always filter the confidence scores against a threshold first to generate a subset, and then defer expensive NumPy matrix operations like `np.argmax` until after filtering. This drastically reduces the workload and significantly improves post-processing performance.
