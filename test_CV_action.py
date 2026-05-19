from unittest.mock import patch, MagicMock
import numpy as np
import cv2

from CV_action import extract_volleyball_ultra_sensitive

@patch('CV_action.pd.DataFrame.to_csv')
@patch('CV_action.VideoFileClip')
@patch('CV_action.cv2.VideoCapture')
@patch('builtins.print')
def test_extract_volleyball_render_exception(mock_print, mock_videocapture, mock_videofileclip, mock_to_csv):
    mock_cap = MagicMock()

    # Mock cap.get for cv2.CAP_PROP_FPS and other properties
    def mock_get(prop_id):
        if prop_id == cv2.CAP_PROP_FPS:
            return 30
        return 100
    mock_cap.get.side_effect = mock_get

    # Mock cap.read to yield two frames then stop
    dummy_frame = np.zeros((100, 100, 3), dtype=np.uint8)
    mock_cap.read.side_effect = [(True, dummy_frame), (True, dummy_frame), (False, None)]

    mock_videocapture.return_value = mock_cap

    # Force exception during VideoFileClip instantiation to simulate a render error
    mock_videofileclip.side_effect = Exception("Test render error")

    extract_volleyball_ultra_sensitive("dummy.mp4", "out.mp4", "out.csv")

    # Verify the Exception handling in extract_volleyball_ultra_sensitive
    # The print should have been called with "Błąd renderowania: Test render error"
    mock_print.assert_any_call("Błąd renderowania: Test render error")
