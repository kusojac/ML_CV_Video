import numpy as np
import time
from VolleyballApp.backend.frame_utilities import get_distance_person_ball_np

# Mock data
np.random.seed(42)
num_persons = 100000
coco_boxes = np.random.randint(0, 640, size=(num_persons, 4))
coco_class_ids = np.zeros(num_persons, dtype=int)
ball_box = np.array([100, 100, 150, 150])

# Baseline
start_time = time.perf_counter()
person_boxes = [coco_boxes[i] for i, cid in enumerate(coco_class_ids) if cid == 0]
min_dist = float('inf')
closest_person_box = None
for pbox in person_boxes:
    dist = get_distance_person_ball_np(pbox, ball_box)
    if dist < min_dist:
        min_dist = dist
        closest_person_box = pbox
baseline_time = time.perf_counter() - start_time
print(f"Baseline time: {baseline_time:.6f} seconds")

# Optimized
start_time = time.perf_counter()
person_boxes_np = coco_boxes[coco_class_ids == 0]
person_centers_x = (person_boxes_np[:, 0] + person_boxes_np[:, 2]) / 2.0
person_centers_y = (person_boxes_np[:, 1] + person_boxes_np[:, 3]) / 2.0
ball_center_x = (ball_box[0] + ball_box[2]) / 2.0
ball_center_y = (ball_box[1] + ball_box[3]) / 2.0
dists = (person_centers_x - ball_center_x) ** 2 + (person_centers_y - ball_center_y) ** 2
closest_idx = np.argmin(dists)
closest_person_box_opt = person_boxes_np[closest_idx]
opt_time = time.perf_counter() - start_time
print(f"Optimized time: {opt_time:.6f} seconds")
print(f"Speedup: {baseline_time / opt_time:.2f}x")

assert np.array_equal(closest_person_box, closest_person_box_opt)
