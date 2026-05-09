import unittest
from unittest import mock
import os
import sys

# Add backend directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from engine import VolleyballAnalyticsEngine

class TestEngineSecurity(unittest.TestCase):
    @mock.patch('pickle.load')
    @mock.patch('onnxruntime.InferenceSession')
    def test_engine_no_pickle(self, mock_onnx, mock_pickle):
        # We also need to mock mp.solutions.pose.Pose because it requires model files
        with mock.patch('mediapipe.solutions.pose.Pose'):
            engine = VolleyballAnalyticsEngine(models_dir="/dummy/models")

            # Assert pickle.load was not called (Insecure Deserialization fix)
            mock_pickle.assert_not_called()

            # Assert ONNX was used instead for the random forest model
            # We expect multiple calls to InferenceSession for yolo and rf_model
            onnx_calls = mock_onnx.call_args_list
            rf_model_loaded = any('model.onnx' in str(call_args) for call_args in onnx_calls)

            self.assertTrue(rf_model_loaded, "ONNX InferenceSession should be used for model.onnx instead of pickle")
