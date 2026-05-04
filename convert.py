import pickle
import numpy as np
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

# load model
model_dict = pickle.load(open("VolleyballApp/backend/models/model.p", "rb"))
rf_model = model_dict["model"]

# The input data has 31 features
initial_type = [('float_input', FloatTensorType([None, 31]))]
onx = convert_sklearn(rf_model, initial_types=initial_type)
with open("VolleyballApp/backend/models/model.onnx", "wb") as f:
    f.write(onx.SerializeToString())
