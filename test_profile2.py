import numpy as np
import time

def get_distance_person_ball_np_old(person_box_np, ball_box_np):
    person_center_x = (person_box_np[0] + person_box_np[2]) / 2
    person_center_y = (person_box_np[1] + person_box_np[3]) / 2
    ball_center_x = (ball_box_np[0] + ball_box_np[2]) / 2
    ball_center_y = (ball_box_np[1] + ball_box_np[3]) / 2
    return np.sqrt((person_center_x - ball_center_x) ** 2 + (person_center_y - ball_center_y) ** 2)

def get_distance_person_ball_np_new(person_box_np, ball_box_np):
    person_center_x = (person_box_np[..., 0] + person_box_np[..., 2]) / 2.0
    person_center_y = (person_box_np[..., 1] + person_box_np[..., 3]) / 2.0
    ball_center_x = (ball_box_np[..., 0] + ball_box_np[..., 2]) / 2.0
    ball_center_y = (ball_box_np[..., 1] + ball_box_np[..., 3]) / 2.0
    return np.sqrt((person_center_x - ball_center_x) ** 2 + (person_center_y - ball_center_y) ** 2)

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
    dist = get_distance_person_ball_np_old(pbox, ball_box)
    if dist < min_dist:
        min_dist = dist
        closest_person_box = pbox
baseline_time = time.perf_counter() - start_time
print(f"Baseline time: {baseline_time:.6f} seconds")

# Optimized
start_time = time.perf_counter()
person_boxes_np = coco_boxes[coco_class_ids == 0]
dists = get_distance_person_ball_np_new(person_boxes_np, ball_box)
closest_idx = np.argmin(dists)
closest_person_box_opt = person_boxes_np[closest_idx]
opt_time = time.perf_counter() - start_time
print(f"Optimized time: {opt_time:.6f} seconds")
print(f"Speedup: {baseline_time / opt_time:.2f}x")

assert np.array_equal(closest_person_box, closest_person_box_opt)
