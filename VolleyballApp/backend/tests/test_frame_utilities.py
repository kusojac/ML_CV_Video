import pytest
import numpy as np
from frame_utilities import preprocess_yolo_input

def test_preprocess_yolo_input_default_size():
    # Arrange: Create a dummy image representing a frame (height=480, width=640, channels=3)
    dummy_image = np.zeros((480, 640, 3), dtype=np.uint8)

    # Act: Process the input using the default size (640, 640)
    output = preprocess_yolo_input(dummy_image)

    # Assert: Check that the output shape matches YOLO expectations
    # Batch size = 1, Channels = 3, Height = 640, Width = 640
    assert output.shape == (1, 3, 640, 640)

    # Assert: Output data type should be float32
    assert output.dtype == np.float32

def test_preprocess_yolo_input_scaling():
    # Arrange: Create an image filled with max intensity values
    dummy_image = np.full((100, 100, 3), 255, dtype=np.uint8)

    # Act: Process the input
    output = preprocess_yolo_input(dummy_image)

    # Assert: Check that max value in input is scaled to 1.0
    assert np.max(output) == 1.0

    # Arrange: Create an image with mixed values
    dummy_image_mixed = np.array([[[0, 127, 255]]], dtype=np.uint8)

    # Act: Process the input
    output_mixed = preprocess_yolo_input(dummy_image_mixed)

    # Assert: Output values should be correctly scaled
    assert np.isclose(np.min(output_mixed), 0.0)
    assert np.isclose(np.max(output_mixed), 1.0)
    assert np.all(output_mixed >= 0.0)
    assert np.all(output_mixed <= 1.0)

def test_preprocess_yolo_input_custom_size():
    # Arrange: Create a dummy image
    dummy_image = np.zeros((480, 640, 3), dtype=np.uint8)

    # Act: Process the input using a custom size
    output = preprocess_yolo_input(dummy_image, input_size=(320, 320))

    # Assert: Output shape should reflect the custom size
    assert output.shape == (1, 3, 320, 320)
