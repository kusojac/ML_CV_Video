import pickle
import numpy as np
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

class RestrictedUnpickler(pickle.Unpickler):
    """
    A restricted version of pickle.Unpickler that only allows loading
    safe modules and classes required for scikit-learn models,
    blocking dangerous builtins like eval or exec.
    """
    def find_class(self, module, name):
        # Allow scikit-learn and numpy namespaces
        if module.startswith(("sklearn.", "numpy.")) or module in {"sklearn", "numpy"}:
            return super().find_class(module, name)

        # Only allow specific safe builtins
        if module == "builtins" and name in {
            "object", "dict", "list", "tuple", "int", "float",
            "str", "bool", "set", "bytes"
        }:
            return super().find_class(module, name)

        # Allow safe reconstruction helpers
        if module == "copyreg" and name == "_reconstructor":
            return super().find_class(module, name)

        if module == "_codecs" and name == "encode":
            return super().find_class(module, name)

        # Forbid everything else
        raise pickle.UnpicklingError(f"global '{module}.{name}' is forbidden")

def restricted_load(file_obj):
    return RestrictedUnpickler(file_obj).load()

# load model securely
try:
    with open("VolleyballApp/backend/models/model.p", "rb") as f:
        model_dict = restricted_load(f)
except FileNotFoundError:
    print("Warning: VolleyballApp/backend/models/model.p not found.")
    model_dict = None

if model_dict:
    rf_model = model_dict["model"]

    # The input data has 31 features
    initial_type = [('float_input', FloatTensorType([None, 31]))]
    onx = convert_sklearn(rf_model, initial_types=initial_type)
    with open("VolleyballApp/backend/models/model.onnx", "wb") as f:
        f.write(onx.SerializeToString())
