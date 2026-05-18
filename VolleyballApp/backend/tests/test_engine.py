import pytest
from unittest import mock
import numpy as np

# We patch these dependencies before importing engine
@pytest.fixture(autouse=True)
def mock_dependencies():
    with mock.patch("onnxruntime.InferenceSession") as mock_ort_session, \
         mock.patch("mediapipe.solutions.pose.Pose") as mock_mp_pose, \
         mock.patch("builtins.open", mock.mock_open()) as mock_file, \
         mock.patch("pickle.load") as mock_pickle:

        # Set up mock returns
        mock_session_instance = mock.MagicMock()
        mock_input = mock.MagicMock()
        mock_input.name = "input"
        mock_session_instance.get_inputs.return_value = [mock_input]
        mock_output = mock.MagicMock()
        mock_output.name = "output"
        mock_session_instance.get_outputs.return_value = [mock_output]
        mock_ort_session.return_value = mock_session_instance

        mock_pickle.return_value = {"model": mock.MagicMock()}

        yield mock_ort_session, mock_mp_pose, mock_file, mock_pickle

def test_engine_initialization(mock_dependencies):
    from engine import VolleyballAnalyticsEngine
    mock_ort, mock_pose, mock_file, mock_pickle = mock_dependencies

    # Act
    engine = VolleyballAnalyticsEngine("/fake/models/dir")

    # Assert
    # Check if ONNX sessions were created
    assert mock_ort.call_count >= 2
    mock_pose.assert_called_once()


def test_process_video_empty(mock_dependencies):
    from engine import VolleyballAnalyticsEngine
    mock_ort, mock_pose, mock_file, mock_pickle = mock_dependencies

    with mock.patch("cv2.VideoCapture") as mock_cap:
        # Arrange
        mock_cap_instance = mock.MagicMock()
        mock_cap_instance.get.side_effect = lambda prop: 30.0 if prop == 5 else 0.0 # FPS=30, TotalFrames=0
        mock_cap_instance.isOpened.return_value = False
        mock_cap.return_value = mock_cap_instance

        engine = VolleyballAnalyticsEngine("/fake")

        # Act
        result = engine.process_video("fake.mp4")

        # Assert
        assert result["total_frames"] == 0
        assert result["fps"] == 30.0
        assert result["actions"] == []


def test_process_video_with_frames(mock_dependencies):
    from engine import VolleyballAnalyticsEngine
    mock_ort, mock_pose, mock_file, mock_pickle = mock_dependencies

    with mock.patch("cv2.VideoCapture") as mock_cap, \
         mock.patch("engine.preprocess_yolo_input") as mock_preprocess, \
         mock.patch.object(VolleyballAnalyticsEngine, "_detect_objects") as mock_detect, \
         mock.patch.object(VolleyballAnalyticsEngine, "_classify_action") as mock_classify, \
         mock.patch("cv2.cvtColor") as mock_cvt:

        # Arrange
        mock_cap_instance = mock.MagicMock()
        mock_cap_instance.get.side_effect = lambda prop: 30.0 if prop == 5 else 3.0 # FPS=30, TotalFrames=3

        # Simulate 3 frames
        frame_read_returns = [(True, np.zeros((100, 100, 3))), (True, np.zeros((100, 100, 3))), (True, np.zeros((100, 100, 3))), (False, None)]
        mock_cap_instance.read.side_effect = frame_read_returns

        # isOpened should return True until we run out of frames
        mock_cap_instance.isOpened.side_effect = [True, True, True, True, False]
        mock_cap.return_value = mock_cap_instance

        mock_cvt.return_value = np.zeros((100, 100, 3))
        mock_preprocess.return_value = np.zeros((1, 3, 640, 640))

        mock_detect.return_value = ([0, 0, 10, 10], [20, 20, 50, 50])

        # Let's say action is NONE, then SPIKE, then SPIKE
        mock_classify.side_effect = ["NONE", "SPIKE", "SPIKE", "NONE"]

        engine = VolleyballAnalyticsEngine("/fake")

        # Act
        result = engine.process_video("fake.mp4")

        # Assert
        assert result["total_frames"] == 3
        assert result["fps"] == 30.0
        assert len(result["actions"]) == 1

        action = result["actions"][0]
        assert action["type"] == "SPIKE"
        # start frame 1 (33.3ms) to frame 3 (100ms)
        assert np.isclose(action["start_ms"], (1 / 30.0) * 1000.0)
        assert np.isclose(action["end_ms"], (3 / 30.0) * 1000.0)

def test_process_video_with_progress_callback(mock_dependencies):
    from engine import VolleyballAnalyticsEngine
    mock_ort, mock_pose, mock_file, mock_pickle = mock_dependencies

    with mock.patch("cv2.VideoCapture") as mock_cap, \
         mock.patch("engine.preprocess_yolo_input") as mock_preprocess, \
         mock.patch.object(VolleyballAnalyticsEngine, "_detect_objects") as mock_detect, \
         mock.patch.object(VolleyballAnalyticsEngine, "_classify_action") as mock_classify, \
         mock.patch("cv2.cvtColor") as mock_cvt:

        mock_cap_instance = mock.MagicMock()
        # Ensure total_frames > 20 so that 5% step is > 1
        mock_cap_instance.get.side_effect = lambda prop: 30.0 if prop == 5 else 40.0

        # Simulate 40 frames
        returns = [(True, np.zeros((10, 10, 3))) for _ in range(40)] + [(False, None)]
        mock_cap_instance.read.side_effect = returns
        mock_cap_instance.isOpened.side_effect = [True] * 40 + [False]
        mock_cap.return_value = mock_cap_instance

        mock_cvt.return_value = np.zeros((10, 10, 3))
        mock_preprocess.return_value = np.zeros((1, 3, 640, 640))
        mock_detect.return_value = ([0, 0, 10, 10], [20, 20, 50, 50])
        mock_classify.return_value = "NONE"

        engine = VolleyballAnalyticsEngine("/fake")

        progress_cb = mock.MagicMock()
        engine.process_video("fake.mp4", progress_callback=progress_cb)

        # 40 frames, step = max(1, int(40 * 0.05)) = max(1, 2) = 2.
        # Should be called for frames 2, 4, 6... 40 -> 20 times.
        assert progress_cb.call_count == 20

def test_process_video_error_handling(mock_dependencies):
    from engine import VolleyballAnalyticsEngine
    mock_ort, mock_pose, mock_file, mock_pickle = mock_dependencies

    with mock.patch("cv2.VideoCapture") as mock_cap:
        mock_cap_instance = mock.MagicMock()
        mock_cap_instance.get.side_effect = lambda prop: 30.0 if prop == 5 else 3.0
        # read throws an exception
        mock_cap_instance.read.side_effect = Exception("Read error")
        mock_cap_instance.isOpened.return_value = True
        mock_cap.return_value = mock_cap_instance

        engine = VolleyballAnalyticsEngine("/fake")

        with pytest.raises(Exception, match="Read error"):
            engine.process_video("fake.mp4")
