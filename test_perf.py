import numpy as np
import time

def original(output, conf_threshold=0.25):
    output = np.squeeze(output)
    if output.shape[0] < output.shape[1]:
        output = output.T

    num_features = output.shape[1]
    boxes_raw = output[:, :4]
    class_scores = output[:, 4:]
    scores = np.max(class_scores, axis=1)
    class_ids = np.argmax(class_scores, axis=1)

    valid_mask = scores > conf_threshold
    boxes_filtered = boxes_raw[valid_mask]
    scores_filtered = scores[valid_mask]
    class_ids_filtered = class_ids[valid_mask]
    return boxes_filtered, scores_filtered, class_ids_filtered

def optimized(output, conf_threshold=0.25):
    output = np.squeeze(output)
    if output.shape[0] < output.shape[1]:
        output = output.T

    num_features = output.shape[1]
    boxes_raw = output[:, :4]
    class_scores = output[:, 4:]
    scores = np.max(class_scores, axis=1)

    valid_mask = scores > conf_threshold
    boxes_filtered = boxes_raw[valid_mask]
    scores_filtered = scores[valid_mask]
    class_scores_filtered = class_scores[valid_mask]
    class_ids_filtered = np.argmax(class_scores_filtered, axis=1)
    return boxes_filtered, scores_filtered, class_ids_filtered

# Create dummy output shape (1, 84, 8400)
# Make most scores low, some high
output = np.random.rand(1, 84, 8400) * 0.2
output[0, 4:, :100] = 0.9

start = time.time()
for _ in range(1000):
    original(output)
orig_time = time.time() - start

start = time.time()
for _ in range(1000):
    optimized(output)
opt_time = time.time() - start

print(f"Original: {orig_time:.4f}s")
print(f"Optimized: {opt_time:.4f}s")
