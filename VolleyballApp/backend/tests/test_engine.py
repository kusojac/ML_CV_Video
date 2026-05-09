import pytest
from unittest.mock import patch, MagicMock
import numpy as np
import sys

# Because main.py is loaded, it might have mocked things.
# Let's remove main and engine from sys.modules to start fresh!
if 'main' in sys.modules:
    del sys.modules['main']
if 'engine' in sys.modules:
    del sys.modules['engine']

import engine

@patch("onnxruntime.InferenceSession")
@patch("mediapipe.solutions.pose.Pose")
@patch("builtins.open", create=True)
@patch("pickle.load", create=True)
def test_engine_init(mock_pickle_load, mock_open, mock_mp_pose, mock_inference_session):
    mock_session = MagicMock()
    mock_input = MagicMock()
    mock_input.name = "mock_input"
    mock_output = MagicMock()
    mock_output.name = "mock_output"
    mock_session.get_inputs.return_value = [mock_input]
    mock_session.get_outputs.return_value = [mock_output]
    mock_inference_session.return_value = mock_session
    mock_pickle_load.return_value = {"model": MagicMock()}

    analytics_engine = engine.VolleyballAnalyticsEngine("dummy_dir")

    assert mock_inference_session.call_count >= 2

@patch("cv2.VideoCapture")
@patch("onnxruntime.InferenceSession")
@patch("mediapipe.solutions.pose.Pose")
@patch("builtins.open", create=True)
@patch("pickle.load", create=True)
def test_process_video(mock_pickle_load, mock_open, mock_mp_pose, mock_inference_session, mock_cap):
    mock_session = MagicMock()
    mock_input = MagicMock()
    mock_input.name = "mock_input"
    mock_output = MagicMock()
    mock_output.name = "mock_output"
    mock_session.get_inputs.return_value = [mock_input]
    mock_session.get_outputs.return_value = [mock_output]
    mock_inference_session.return_value = mock_session
    mock_pickle_load.return_value = {"model": MagicMock()}

    analytics_engine = engine.VolleyballAnalyticsEngine("dummy_dir")

    mock_cap_instance = MagicMock()
    mock_cap.return_value = mock_cap_instance
    mock_cap_instance.get.side_effect = [30.0, 10]
    mock_cap_instance.isOpened.side_effect = [True] * 10 + [False]
    dummy_frame = np.zeros((100, 100, 3), dtype=np.uint8)
    mock_cap_instance.read.side_effect = [(True, dummy_frame)] * 10 + [(False, None)]

    with patch.object(analytics_engine, '_detect_objects') as mock_detect, \
         patch.object(analytics_engine, '_classify_action') as mock_classify, \
         patch("engine.preprocess_yolo_input") as mock_preprocess:

        mock_preprocess.return_value = np.zeros((1, 3, 640, 640), dtype=np.float32)
        mock_detect.return_value = ([0, 0, 10, 10], [10, 10, 20, 20])
        mock_classify.side_effect = ["NONE"] + ["Serve"] * 4 + ["NONE"] * 5

        result = analytics_engine.process_video("dummy.mp4")

        assert result["fps"] == 30.0
        assert result["total_frames"] == 10
        assert len(result["actions"]) == 1

@patch("cv2.VideoCapture")
@patch("onnxruntime.InferenceSession")
@patch("mediapipe.solutions.pose.Pose")
@patch("builtins.open", create=True)
@patch("pickle.load", create=True)
def test_process_video_error_handling(mock_pickle_load, mock_open, mock_mp_pose, mock_inference_session, mock_cap):
    mock_session = MagicMock()
    mock_input = MagicMock()
    mock_input.name = "mock_input"
    mock_session.get_inputs.return_value = [mock_input]
    mock_session.get_outputs.return_value = [mock_input]
    mock_inference_session.return_value = mock_session
    mock_pickle_load.return_value = {"model": MagicMock()}

    analytics_engine = engine.VolleyballAnalyticsEngine("dummy_dir")

    mock_cap_instance = MagicMock()
    mock_cap.return_value = mock_cap_instance
    mock_cap_instance.get.side_effect = [0.0, 0]
    mock_cap_instance.isOpened.return_value = False

    result = analytics_engine.process_video("dummy.mp4")

    assert result["fps"] == 30.0

@patch("cv2.VideoCapture")
@patch("onnxruntime.InferenceSession")
@patch("mediapipe.solutions.pose.Pose")
@patch("builtins.open", create=True)
@patch("pickle.load", create=True)
def test_process_video_flush_last_action(mock_pickle_load, mock_open, mock_mp_pose, mock_inference_session, mock_cap):
    mock_session = MagicMock()
    mock_input = MagicMock()
    mock_input.name = "mock_input"
    mock_output = MagicMock()
    mock_output.name = "mock_output"
    mock_session.get_inputs.return_value = [mock_input]
    mock_session.get_outputs.return_value = [mock_output]
    mock_inference_session.return_value = mock_session
    mock_pickle_load.return_value = {"model": MagicMock()}

    analytics_engine = engine.VolleyballAnalyticsEngine("dummy_dir")

    mock_cap_instance = MagicMock()
    mock_cap.return_value = mock_cap_instance
    mock_cap_instance.get.side_effect = [30.0, 3]
    mock_cap_instance.isOpened.side_effect = [True] * 3 + [False]
    dummy_frame = np.zeros((100, 100, 3), dtype=np.uint8)
    mock_cap_instance.read.side_effect = [(True, dummy_frame)] * 3 + [(False, None)]

    with patch.object(analytics_engine, '_detect_objects') as mock_detect, \
         patch.object(analytics_engine, '_classify_action') as mock_classify, \
         patch("engine.preprocess_yolo_input") as mock_preprocess:

        mock_preprocess.return_value = np.zeros((1, 3, 640, 640), dtype=np.float32)
        mock_detect.return_value = ([0, 0, 10, 10], [10, 10, 20, 20])
        mock_classify.side_effect = ["Spike", "Spike", "Spike"]

        result = analytics_engine.process_video("dummy.mp4")

        assert result["total_frames"] == 3
        assert len(result["actions"]) == 1
