import numpy as np
import pytest
from frame_utilities import pad_frame_to_square, get_distance_person_ball_np

def test_pad_frame_to_square_square():
    # Create a 100x100 square frame
    frame = np.zeros((100, 100, 3), dtype=np.uint8)
    padded, pad_l, pad_t = pad_frame_to_square(frame)

    assert padded.shape == (100, 100, 3)
    assert pad_l == 0
    assert pad_t == 0
    np.testing.assert_array_equal(padded, frame)

def test_pad_frame_to_square_tall():
    # Create a 200x100 tall frame
    frame = np.zeros((200, 100, 3), dtype=np.uint8)
    # Fill it with a specific color to verify padding
    frame[:] = (255, 255, 255)

    padded, pad_l, pad_t = pad_frame_to_square(frame)

    # Target shape should be 200x200
    assert padded.shape == (200, 200, 3)
    assert pad_l == (200 - 100) // 2  # 50
    assert pad_t == 0

    # Check that the original frame is in the middle
    # pad_left is 50, pad_right is 50
    np.testing.assert_array_equal(padded[:, 50:150, :], frame)
    # Check padding is black (0, 0, 0)
    assert np.all(padded[:, :50, :] == 0)
    assert np.all(padded[:, 150:, :] == 0)

def test_pad_frame_to_square_wide():
    # Create a 100x200 wide frame
    frame = np.zeros((100, 200, 3), dtype=np.uint8)
    frame[:] = (255, 255, 255)

    padded, pad_l, pad_t = pad_frame_to_square(frame)

    # Target shape should be 200x200
    assert padded.shape == (200, 200, 3)
    assert pad_l == 0
    assert pad_t == (200 - 100) // 2  # 50

    # Check that the original frame is in the middle
    # pad_top is 50, pad_bottom is 50
    np.testing.assert_array_equal(padded[50:150, :, :], frame)
    # Check padding is black (0, 0, 0)
    assert np.all(padded[:50, :, :] == 0)
    assert np.all(padded[150:, :, :] == 0)

def test_pad_frame_to_square_odd_padding():
    # 101 x 100 (tall) -> padding = 1. pad_left = 0, pad_right = 1.
    frame = np.ones((101, 100, 3), dtype=np.uint8)
    padded, pad_l, pad_t = pad_frame_to_square(frame)
    assert padded.shape == (101, 101, 3)
    assert pad_l == 0
    assert pad_t == 0
    np.testing.assert_array_equal(padded[:, 0:100, :], frame)
    assert np.all(padded[:, 100:, :] == 0)

    # 100 x 101 (wide) -> padding = 1. pad_top = 0, pad_bottom = 1.
    frame = np.ones((100, 101, 3), dtype=np.uint8)
    padded, pad_l, pad_t = pad_frame_to_square(frame)
    assert padded.shape == (101, 101, 3)
    assert pad_l == 0
    assert pad_t == 0
    np.testing.assert_array_equal(padded[0:100, :, :], frame)
    assert np.all(padded[100:, :, :] == 0)

def test_get_distance_person_ball_np():
    person_box = np.array([0, 0, 10, 10]) # center (5, 5)
    ball_box = np.array([10, 10, 20, 20]) # center (15, 15)

    # distance = sqrt((15-5)^2 + (15-5)^2) = sqrt(100 + 100) = sqrt(200) approx 14.142
    dist = get_distance_person_ball_np(person_box, ball_box)
    assert dist == pytest.approx(np.sqrt(200))

from frame_utilities import preprocess_yolo_input

def test_preprocess_yolo_input_default():
    image = np.zeros((1080, 1920, 3), dtype=np.uint8)
    output = preprocess_yolo_input(image)
    assert output.shape == (1, 3, 640, 640)
    assert output.dtype == np.float32

def test_preprocess_yolo_input_custom_size():
    image = np.zeros((1080, 1920, 3), dtype=np.uint8)
    output = preprocess_yolo_input(image, input_size=(320, 320))
    assert output.shape == (1, 3, 320, 320)
    assert output.dtype == np.float32

def test_preprocess_yolo_input_value_scaling():
    # Test that values are scaled to [0, 1]
    image = np.ones((640, 640, 3), dtype=np.uint8) * 255
    output = preprocess_yolo_input(image)
    assert np.allclose(output, 1.0)

    image_half = np.ones((640, 640, 3), dtype=np.uint8) * 127
    output_half = preprocess_yolo_input(image_half)
    assert np.allclose(output_half, 127 / 255.0)

from frame_utilities import postprocess_yolo_output

def test_postprocess_yolo_output_ball_below_threshold():
    # Arrange: output shape (1, 5, 100), all confidences below 0.25
    output = np.zeros((1, 5, 100), dtype=np.float32)
    output[0, 4, :] = 0.1

    # Act
    boxes, scores, class_ids = postprocess_yolo_output(
        output,
        original_img_shape=(1080, 1920),
        input_size=(640, 640),
        conf_threshold=0.25
    )

    # Assert
    assert boxes.shape == (0, 4)
    assert scores.shape == (0,)
    assert class_ids.shape == (0,)

def test_postprocess_yolo_output_coco_below_threshold():
    # Arrange: output shape (1, 84, 100), all max confidences below 0.25
    output = np.zeros((1, 84, 100), dtype=np.float32)
    output[0, 4:, :] = 0.1

    # Act
    boxes, scores, class_ids = postprocess_yolo_output(
        output,
        original_img_shape=(1080, 1920),
        input_size=(640, 640),
        conf_threshold=0.25
    )

    # Assert
    assert boxes.shape == (0, 4)
    assert scores.shape == (0,)
    assert class_ids.shape == (0,)

def test_postprocess_yolo_output_ball_valid():
    # Arrange: output shape (1, 5, 100), one valid confidence above 0.25
    output = np.zeros((1, 5, 100), dtype=np.float32)
    # Box: x_center, y_center, width, height, confidence
    output[0, :, 0] = [320, 320, 50, 50, 0.9]

    # Act
    boxes, scores, class_ids = postprocess_yolo_output(
        output,
        original_img_shape=(1080, 1920),
        input_size=(640, 640),
        conf_threshold=0.25
    )

    # Assert
    assert boxes.shape == (1, 4)
    assert scores.shape == (1,)
    assert class_ids.shape == (1,)
    assert scores[0] == pytest.approx(0.9)
    assert class_ids[0] == 0
    # Center 320 on 640x640 is mid. Scale to 1920x1080: scale_x = 1920/640=3, scale_y=1080/640=1.6875
    # x1 = (320 - 25) * 3 = 295 * 3 = 885
    # y1 = (320 - 25) * 1.6875 = 295 * 1.6875 = 497.8125 -> int -> 497
    # x2 = (320 + 25) * 3 = 345 * 3 = 1035
    # y2 = (320 + 25) * 1.6875 = 345 * 1.6875 = 582.1875 -> int -> 582
    expected_box = [885, 497, 1035, 582]
    np.testing.assert_array_equal(boxes[0], expected_box)

def test_postprocess_yolo_output_coco_valid():
    # Arrange: output shape (1, 84, 100), one valid
    output = np.zeros((1, 84, 100), dtype=np.float32)
    output[0, :4, 0] = [320, 320, 50, 50]
    output[0, 4, 0] = 0.9 # class 0 score 0.9

    # Act
    boxes, scores, class_ids = postprocess_yolo_output(
        output,
        original_img_shape=(1080, 1920),
        input_size=(640, 640),
        conf_threshold=0.25
    )

    # Assert
    assert boxes.shape == (1, 4)
    assert scores.shape == (1,)
    assert class_ids.shape == (1,)
    assert scores[0] == pytest.approx(0.9)
    assert class_ids[0] == 0

def test_postprocess_yolo_output_coco_target_class_id():
    # Arrange: output shape (1, 84, 100), testing target_class_id optimization
    output = np.zeros((1, 84, 100), dtype=np.float32)
    # Box 1: Class 0 is high confidence
    output[0, :4, 0] = [320, 320, 50, 50]
    output[0, 4, 0] = 0.9 # class 0 score 0.9

    # Box 2: Class 1 is high confidence (should be ignored if target_class_id=0)
    output[0, :4, 1] = [100, 100, 20, 20]
    output[0, 5, 1] = 0.8 # class 1 score 0.8

    # Act
    boxes, scores, class_ids = postprocess_yolo_output(
        output,
        original_img_shape=(1080, 1920),
        input_size=(640, 640),
        conf_threshold=0.25,
        target_class_id=0
    )

    # Assert
    assert boxes.shape == (1, 4)
    assert scores.shape == (1,)
    assert class_ids.shape == (1,)
    assert scores[0] == pytest.approx(0.9)
    assert class_ids[0] == 0


def test_postprocess_yolo_output_invalid_features():
    # Arrange: model output with 10 features (neither 5 nor 84)
    output = np.zeros((1, 10, 100), dtype=np.float32)

    # Act
    boxes, scores, class_ids = postprocess_yolo_output(
        output,
        original_img_shape=(1080, 1920),
        input_size=(640, 640),
        conf_threshold=0.25
    )

    # Assert
    assert boxes.shape == (0, 4)
    assert scores.shape == (0,)
    assert class_ids.shape == (0,)
