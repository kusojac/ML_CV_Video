import numpy as np
import cv2
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
