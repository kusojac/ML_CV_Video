import numpy as np
import time

def run_benchmark(optimized=False):
    output = np.random.rand(1, 84, 8400) * 0.1
    output[0, 4:, :50] = 0.9

    output = np.squeeze(output)
    if output.shape[0] < output.shape[1]:
        output = output.T

    boxes_raw = output[:, :4]
    class_scores = output[:, 4:]

    start_time = time.time()
    for _ in range(1000):
        if not optimized:
            scores = np.max(class_scores, axis=1)
            valid_mask = scores > 0.25
            boxes_filtered = boxes_raw[valid_mask]
            scores_filtered = scores[valid_mask]
            class_ids_filtered = np.argmax(class_scores[valid_mask], axis=1)
        else:
            scores = class_scores[:, 0] # target_class_id = 0
            valid_mask = scores > 0.25
            boxes_filtered = boxes_raw[valid_mask]
            scores_filtered = scores[valid_mask]
            class_ids_filtered = np.zeros(len(scores_filtered), dtype=int)

    end_time = time.time()
    return end_time - start_time

t1 = run_benchmark(False)
t2 = run_benchmark(True)
print(f"Original: {t1:.4f}s")
print(f"Optimized: {t2:.4f}s")
