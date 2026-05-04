import numpy as np
from VolleyballApp.backend.frame_utilities import postprocess_yolo_output

def test_postprocess_yolo_output():
    # Mock YOLO output: 1 image, 84 classes, 100 anchor boxes
    # Shape: (1, 84, 100) since num_anchors > num_features is required by engine.py logic
    mock_output = np.random.rand(1, 84, 100) * 0.1
    # Set high confidence for the first anchor box, class index 0 (person)
    mock_output[0, 4, 0] = 0.9
    mock_output[0, 0:4, 0] = [100, 100, 50, 50] # x_center, y_center, width, height

    # Original image shape (720, 1280, 3)
    original_shape = (720, 1280, 3)

    boxes, scores, class_ids = postprocess_yolo_output(mock_output, original_shape)

    assert len(boxes) == 1
    assert len(scores) == 1
    assert len(class_ids) == 1
    assert class_ids[0] == 0
    assert scores[0] > 0.8
    print("All tests passed.")

if __name__ == "__main__":
    test_postprocess_yolo_output()
