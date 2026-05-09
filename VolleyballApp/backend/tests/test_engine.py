import pytest
from unittest.mock import patch, MagicMock
import numpy as np
import os
import sys

# Ensure VolleyballApp/backend is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from engine import VolleyballAnalyticsEngine

@patch('engine.onnxruntime.InferenceSession')
@patch('engine.mp.solutions.pose.Pose')
@patch('builtins.open')
@patch('pickle.load')
def test_engine_init(mock_pickle_load, mock_open, mock_pose, mock_onnx_session):
    # Setup mocks
    mock_session_instance = MagicMock()
    mock_session_instance.get_inputs.return_value = [MagicMock(name='input')]
    mock_session_instance.get_outputs.return_value = [MagicMock(name='output')]
    mock_onnx_session.return_value = mock_session_instance

    mock_pickle_load.return_value = {"model": "dummy"}

    engine = VolleyballAnalyticsEngine("/dummy/path")

    # Assertions
    # In the original code, InferenceSession is called twice (COCO and VB)
    assert mock_onnx_session.call_count >= 2
    mock_pose.assert_called_once()

    assert hasattr(engine, 'mp_pose')
    assert hasattr(engine, 'session_coco')
    assert hasattr(engine, 'session_vb')

@patch('engine.cv2.VideoCapture')
@patch.object(VolleyballAnalyticsEngine, '_detect_objects')
@patch.object(VolleyballAnalyticsEngine, '_classify_action')
@patch('engine.onnxruntime.InferenceSession')
@patch('engine.mp.solutions.pose.Pose')
@patch('builtins.open')
@patch('pickle.load')
def test_engine_process_video(mock_pickle_load, mock_open, mock_pose, mock_onnx_session,
                              mock_classify_action, mock_detect_objects, mock_video_capture):

    # Mock init components
    mock_session_instance = MagicMock()
    mock_session_instance.get_inputs.return_value = [MagicMock(name='input')]
    mock_session_instance.get_outputs.return_value = [MagicMock(name='output')]
    mock_onnx_session.return_value = mock_session_instance

    mock_pickle_load.return_value = {"model": "dummy"}

    # Mock cv2 VideoCapture
    mock_cap = MagicMock()
    mock_video_capture.return_value = mock_cap
    mock_cap.get.side_effect = lambda prop: 30.0 if prop == 5 else 10 # 5 is cv2.CAP_PROP_FPS, 10 frames
    mock_cap.isOpened.return_value = True

    # Simulate 10 frames then stop
    frames_read = 0
    def mock_read():
        nonlocal frames_read
        if frames_read < 10:
            frames_read += 1
            # Return true and a dummy frame
            return True, np.zeros((480, 640, 3), dtype=np.uint8)
        else:
            mock_cap.isOpened.return_value = False
            return False, None
    mock_cap.read.side_effect = mock_read

    # Mock object detection and classification
    # Let's say action is "JUMP" for all frames
    mock_detect_objects.return_value = ([0, 0, 10, 10], [10, 10, 20, 20]) # ball_box, person_box
    mock_classify_action.return_value = "JUMP"

    # Create engine and process video
    engine = VolleyballAnalyticsEngine("/dummy/path")

    # Run test
    results = engine.process_video("/dummy/video.mp4")

    # Assertions
    mock_video_capture.assert_called_with("/dummy/video.mp4")
    assert results["total_frames"] == 10
    assert results["fps"] == 30.0

    # Check actions were accumulated into one continuous action
    assert len(results["actions"]) == 1
    assert results["actions"][0]["type"] == "JUMP"
    assert results["actions"][0]["start_ms"] == 0.0 # Started at first frame

    # Ensure detect and classify were called 10 times
    assert mock_detect_objects.call_count == 10
    assert mock_classify_action.call_count == 10

    mock_cap.release.assert_called_once()
