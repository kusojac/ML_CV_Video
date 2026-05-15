import pickle
import numpy as np
import builtins
import io
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

class RestrictedUnpickler(pickle.Unpickler):
    def find_class(self, module, name):
        # Allow safe built-in primitive types
        if module == "builtins" and name in {"dict", "list", "tuple", "set", "int", "float", "bool", "str", "bytes"}:
            return getattr(builtins, name)

        # Whitelist safe scikit-learn and numpy namespaces
        if module.startswith("sklearn.") or module.startswith("numpy.") or module == "numpy":
            return super().find_class(module, name)

        raise pickle.UnpicklingError(f"Global '{module}.{name}' is forbidden")

# load model
with open("VolleyballApp/backend/models/model.p", "rb") as f:
    model_dict = RestrictedUnpickler(f).load()
rf_model = model_dict["model"]

# The input data has 31 features
initial_type = [('float_input', FloatTensorType([None, 31]))]
onx = convert_sklearn(rf_model, initial_types=initial_type)
with open("VolleyballApp/backend/models/model.onnx", "wb") as f:
    f.write(onx.SerializeToString())
