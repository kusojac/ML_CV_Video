import numpy as np
import time

def run_benchmark(defer_argmax=False):
    # Simulate YOLOv8 COCO output: 1 batch, 84 features (4 box + 80 class), 8400 anchors
    # Memory says: mock data must simulate real-world distributions (mostly low confidence scores)
    output = np.random.rand(1, 84, 8400) * 0.1
    # Add a few high confidence ones
    output[0, 4:, :50] = 0.9

    output = np.squeeze(output)
    if output.shape[0] < output.shape[1]:
        output = output.T

    boxes_raw = output[:, :4]
    class_scores = output[:, 4:]

    start_time = time.time()
    for _ in range(1000):
        if not defer_argmax:
            scores = np.max(class_scores, axis=1)
            class_ids = np.argmax(class_scores, axis=1)
            valid_mask = scores > 0.25
            boxes_filtered = boxes_raw[valid_mask]
            scores_filtered = scores[valid_mask]
            class_ids_filtered = class_ids[valid_mask]
        else:
            scores = np.max(class_scores, axis=1)
            valid_mask = scores > 0.25
            boxes_filtered = boxes_raw[valid_mask]
            scores_filtered = scores[valid_mask]
            class_ids_filtered = np.argmax(class_scores[valid_mask], axis=1)

    end_time = time.time()
    return end_time - start_time

t1 = run_benchmark(False)
t2 = run_benchmark(True)

print(f"Original: {t1:.4f}s")
print(f"Optimized: {t2:.4f}s")
