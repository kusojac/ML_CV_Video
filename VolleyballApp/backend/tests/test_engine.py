import pytest
from unittest.mock import patch, MagicMock, mock_open
import os
import numpy as np

# A completely clean import to sidestep global mocks from test_main

import sys
if 'engine' in sys.modules:
    del sys.modules['engine']

from engine import VolleyballAnalyticsEngine

@patch("engine.onnxruntime.InferenceSession")
@patch("engine.mp.solutions.pose.Pose")
@patch("builtins.open", new_callable=mock_open)
@patch("pickle.load")
def test_engine_init(mock_pickle_load, mock_file_open, mock_pose, mock_inference_session):
    mock_session_instance = MagicMock()
    mock_input = MagicMock()
    mock_input.name = "mock_input"
    mock_output = MagicMock()
    mock_output.name = "mock_output"

    mock_session_instance.get_inputs.return_value = [mock_input]
    mock_session_instance.get_outputs.return_value = [mock_output]
    mock_inference_session.return_value = mock_session_instance

    mock_pickle_load.return_value = {"model": MagicMock()}

    models_dir = "/fake/models"

    # Run init
    e = VolleyballAnalyticsEngine(models_dir)

    calls = mock_inference_session.call_args_list
    args_list = [call[0][0] for call in calls]

    # Use real os.path.join for reliable asserts
    assert os.path.join(models_dir, "yolo11n.onnx") in args_list
    assert os.path.join(models_dir, "yolo11n_vb.onnx") in args_list

    assert e.input_name_coco == "mock_input"
    assert e.output_name_coco == "mock_output"

    mock_pose.assert_called_once_with(min_detection_confidence=0.5, min_tracking_confidence=0.5)

@patch("engine.onnxruntime.InferenceSession")
@patch("engine.mp.solutions.pose.Pose")
@patch("engine.cv2.VideoCapture")
@patch("builtins.open", new_callable=mock_open)
@patch("pickle.load")
def test_engine_process_video_happy_path(mock_pickle_load, mock_file_open, mock_video_capture, mock_pose, mock_inference_session):
    mock_session_coco = MagicMock()
    mock_input_coco = MagicMock(); mock_input_coco.name = "coco_in"
    mock_output_coco = MagicMock(); mock_output_coco.name = "coco_out"
    mock_session_coco.get_inputs.return_value = [mock_input_coco]
    mock_session_coco.get_outputs.return_value = [mock_output_coco]

    mock_session_vb = MagicMock()
    mock_input_vb = MagicMock(); mock_input_vb.name = "vb_in"
    mock_output_vb = MagicMock(); mock_output_vb.name = "vb_out"
    mock_session_vb.get_inputs.return_value = [mock_input_vb]
    mock_session_vb.get_outputs.return_value = [mock_output_vb]

    mock_session_rf = MagicMock()
    mock_input_rf = MagicMock(); mock_input_rf.name = "rf_in"
    mock_session_rf.get_inputs.return_value = [mock_input_rf]

    def session_side_effect(path, *args, **kwargs):
        if "yolo11n.onnx" in path:
            return mock_session_coco
        elif "yolo11n_vb.onnx" in path:
            return mock_session_vb
        elif "model.onnx" in path:
            return mock_session_rf
        return MagicMock()

    mock_inference_session.side_effect = session_side_effect

    mock_rf_model = MagicMock()
    mock_rf_model.predict.return_value = ["SPIKE"]
    mock_pickle_load.return_value = {"model": mock_rf_model}

    mock_cap = MagicMock()
    mock_cap.isOpened.side_effect = [True, True, True, True, True, False]

    dummy_frame = np.zeros((1080, 1920, 3), dtype=np.uint8)
    mock_cap.read.return_value = (True, dummy_frame)
    mock_cap.get.side_effect = lambda prop: 30.0 if prop == 5 else 5
    mock_video_capture.return_value = mock_cap

    vb_out = np.zeros((1, 5, 100), dtype=np.float32)
    vb_out[0, :4, 0] = [320, 320, 50, 50]
    vb_out[0, 4, 0] = 0.9
    mock_session_vb.run.return_value = [vb_out]

    coco_out = np.zeros((1, 84, 100), dtype=np.float32)
    coco_out[0, :4, 0] = [320, 320, 100, 200]
    coco_out[0, 4, 0] = 0.9
    mock_session_coco.run.return_value = [coco_out]

    mock_pose_instance = MagicMock()
    mock_pose_result = MagicMock()
    mock_landmark = MagicMock()
    mock_landmark.x = 0.5
    mock_landmark.y = 0.5
    mock_pose_result.pose_landmarks.landmark = [mock_landmark] * 33
    mock_pose_instance.process.return_value = mock_pose_result
    mock_pose.return_value = mock_pose_instance

    mock_session_rf.run.return_value = [["SPIKE"]]

    e = VolleyballAnalyticsEngine("/fake/models")

    if hasattr(e, 'rf_model'):
        e.rf_model.predict = MagicMock(return_value=["SPIKE"])

    # Grab original unbound function unpatched
    import engine as raw_engine
    func = raw_engine.VolleyballAnalyticsEngine.process_video
    # Remove mock wrappers if any
    while hasattr(func, "__wrapped__"):
        func = func.__wrapped__

    result = func(e, "fake_video.mp4")

    assert result["total_frames"] == 5
    assert result["fps"] == 30.0

    actions = result["actions"]
    assert len(actions) == 1
    action = actions[0]
    assert action["type"] == "SPIKE"

@patch("engine.onnxruntime.InferenceSession")
@patch("engine.mp.solutions.pose.Pose")
@patch("engine.cv2.VideoCapture")
@patch("builtins.open", new_callable=mock_open)
@patch("pickle.load")
def test_engine_process_video_no_objects(mock_pickle_load, mock_file_open, mock_video_capture, mock_pose, mock_inference_session):
    mock_session_coco = MagicMock()
    mock_input_coco = MagicMock(); mock_input_coco.name = "coco_in"
    mock_output_coco = MagicMock(); mock_output_coco.name = "coco_out"
    mock_session_coco.get_inputs.return_value = [mock_input_coco]
    mock_session_coco.get_outputs.return_value = [mock_output_coco]

    mock_session_vb = MagicMock()
    mock_input_vb = MagicMock(); mock_input_vb.name = "vb_in"
    mock_output_vb = MagicMock(); mock_output_vb.name = "vb_out"
    mock_session_vb.get_inputs.return_value = [mock_input_vb]
    mock_session_vb.get_outputs.return_value = [mock_output_vb]

    mock_session_rf = MagicMock()
    mock_input_rf = MagicMock(); mock_input_rf.name = "rf_in"
    mock_session_rf.get_inputs.return_value = [mock_input_rf]

    def session_side_effect(path, *args, **kwargs):
        if "yolo11n.onnx" in path:
            return mock_session_coco
        elif "yolo11n_vb.onnx" in path:
            return mock_session_vb
        elif "model.onnx" in path:
            return mock_session_rf
        return MagicMock()

    mock_inference_session.side_effect = session_side_effect

    mock_pickle_load.return_value = {"model": MagicMock()}

    mock_cap = MagicMock()
    mock_cap.isOpened.side_effect = [True, True, True, False]

    dummy_frame = np.zeros((1080, 1920, 3), dtype=np.uint8)
    mock_cap.read.return_value = (True, dummy_frame)
    mock_cap.get.side_effect = lambda prop: 30.0 if prop == 5 else 3
    mock_video_capture.return_value = mock_cap

    vb_out = np.zeros((1, 5, 100), dtype=np.float32)
    vb_out[0, 4, :] = 0.1
    mock_session_vb.run.return_value = [vb_out]

    coco_out = np.zeros((1, 84, 100), dtype=np.float32)
    coco_out[0, 4:, :] = 0.1
    mock_session_coco.run.return_value = [coco_out]

    e = VolleyballAnalyticsEngine("/fake/models")

    callback_mock = MagicMock()

    import engine as raw_engine
    func = raw_engine.VolleyballAnalyticsEngine.process_video
    while hasattr(func, "__wrapped__"):
        func = func.__wrapped__

    result = func(e, "fake_video.mp4", progress_callback=callback_mock)

    assert result["total_frames"] == 3
    assert result["fps"] == 30.0
    assert len(result["actions"]) == 0
