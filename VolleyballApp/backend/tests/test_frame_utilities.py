import numpy as np
import pytest
from frame_utilities import get_distance_person_ball_np

def test_get_distance_person_ball_np_identical_boxes():
    # If the boxes are identical, the distance should be 0
    person_box = np.array([10, 10, 20, 20])
    ball_box = np.array([10, 10, 20, 20])

    distance = get_distance_person_ball_np(person_box, ball_box)
    assert distance == 0.0

def test_get_distance_person_ball_np_horizontal_separation():
    # Person center is at (15, 15)
    person_box = np.array([10, 10, 20, 20])
    # Ball center is at (25, 15)
    ball_box = np.array([20, 10, 30, 20])

    distance = get_distance_person_ball_np(person_box, ball_box)
    assert distance == 10.0

def test_get_distance_person_ball_np_vertical_separation():
    # Person center is at (15, 15)
    person_box = np.array([10, 10, 20, 20])
    # Ball center is at (15, 25)
    ball_box = np.array([10, 20, 20, 30])

    distance = get_distance_person_ball_np(person_box, ball_box)
    assert distance == 10.0

def test_get_distance_person_ball_np_diagonal_separation():
    # Person center is at (5, 5)
    person_box = np.array([0, 0, 10, 10])
    # Ball center is at (8, 9)
    ball_box = np.array([6, 7, 10, 11])

    distance = get_distance_person_ball_np(person_box, ball_box)

    # Distance = sqrt((8-5)^2 + (9-5)^2) = sqrt(3^2 + 4^2) = sqrt(9+16) = sqrt(25) = 5
    assert distance == 5.0
