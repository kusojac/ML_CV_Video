
## 2025-05-04 - Fix Insecure Deserialization Vulnerability
**Vulnerability:** The backend loaded a Random Forest classifier using `pickle.load()` (`model.p`), exposing the system to arbitrary code execution (RCE) via insecure deserialization.
**Learning:** Machine learning models serialized using Python's native `pickle` format are unsafe to deserialize, especially in production environments where malicious actors could manipulate the file.
**Prevention:** Avoid `pickle` entirely for model storage. Always serialize machine learning models into safe representations like ONNX (via `skl2onnx`) and load them using secure engines like `onnxruntime`.
