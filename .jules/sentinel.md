## 2024-05-04 - Insecure Deserialization via pickle.load

**Vulnerability:** The application used `pickle.load` to load a Random Forest model (`model.p`) in `VolleyballApp/backend/engine.py`. This is an insecure deserialization vulnerability, as an attacker who can modify or replace the `model.p` file could execute arbitrary Python code when the backend server starts and instantiates the `VolleyballAnalyticsEngine` class.

**Learning:** When loading machine learning models from disk, especially in an environment where the model files might be externally supplied or altered, using format-specific binary loaders like `onnxruntime` or safer serialization like `joblib` (with `safe_load=True` if applicable) should always be preferred over Python's built-in `pickle`.

**Prevention:** Avoid `pickle.load` for external or untrusted data. Standardize on secure model representation formats like ONNX, which separates the model architecture and weights from general-purpose execution context, eliminating the code execution risk inherent to unpickling.
