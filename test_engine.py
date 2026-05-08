import onnxruntime
import numpy as np

sess = onnxruntime.InferenceSession("VolleyballApp/backend/models/model.onnx")
input_name = sess.get_inputs()[0].name

X = np.random.rand(1, 31).astype(np.float32)
res = sess.run(None, {input_name: X})

print("Result shape:", len(res))
print("res[0]:", res[0])
print("res[1]:", res[1])
