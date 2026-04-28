import cv2
import math
import os
import onnxruntime
import pickle
import mediapipe as mp
import numpy as np
from frame_utilities import preprocess_yolo_input, postprocess_yolo_output, get_distance_person_ball_np, pad_frame_to_square

class VolleyballAnalyticsEngine:
    def __init__(self, models_dir):
        providers = ["DmlExecutionProvider", "CPUExecutionProvider"]
        
        # Load Person detection YOLO
        self.session_coco = onnxruntime.InferenceSession(os.path.join(models_dir, "yolo11n.onnx"), providers=providers)
        self.input_name_coco = self.session_coco.get_inputs()[0].name
        self.output_name_coco = self.session_coco.get_outputs()[0].name
        
        # Load Volleyball detection YOLO
        self.session_vb = onnxruntime.InferenceSession(os.path.join(models_dir, "yolo11n_vb.onnx"), providers=providers)
        self.input_name_vb = self.session_vb.get_inputs()[0].name
        self.output_name_vb = self.session_vb.get_outputs()[0].name
        
        # RandomForest for actions
        model_dict = pickle.load(open(os.path.join(models_dir, "model.p"), "rb"))
        self.rf_model = model_dict["model"]
        
        # MediaPipe pose
        self.mp_pose = mp.solutions.pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)
        
    def process_video(self, video_path, progress_callback=None):
        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        if fps == 0:
            fps = 30.0

        results = []
        frame_idx = 0
        
        # For deduplicating actions
        current_action_type = "NONE"
        current_action_start = None
        current_action_boxes = []

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            original_shape = frame.shape
            
            timestamp_ms = (frame_idx / fps) * 1000.0
            
            # Bolt Optimization: Preprocess YOLO input once and reuse for both models
            # This saves redundant image resizing and array operations per frame
            yolo_input = preprocess_yolo_input(frame_rgb)

            # 1. Detect Ball
            ball_outs = self.session_vb.run([self.output_name_vb], {self.input_name_vb: yolo_input})
            ball_boxes, ball_scores, _ = postprocess_yolo_output(ball_outs[0], original_shape, conf_threshold=0.5)
            
            detected_action = "NONE"
            closest_person_box = None
            detected_ball_box = None
            
            if len(ball_boxes) > 0:
                # 2. Detect Persons
                coco_outs = self.session_coco.run([self.output_name_coco], {self.input_name_coco: yolo_input})
                coco_boxes, coco_scores, coco_class_ids = postprocess_yolo_output(coco_outs[0], original_shape, conf_threshold=0.5)
                
                person_boxes = [coco_boxes[i] for i, cid in enumerate(coco_class_ids) if cid == 0]
                
                if len(person_boxes) > 0:
                    ball_box_index = np.argmax(ball_scores)
                    ball_box = ball_boxes[ball_box_index]
                    detected_ball_box = ball_box

                    # Find closest person to the best ball prediction
                    min_dist = float('inf')
                    for pbox in person_boxes:
                        dist = get_distance_person_ball_np(pbox, ball_box)
                        if dist < min_dist:
                            min_dist = dist
                            closest_person_box = pbox
                            
                    px_min, py_min, px_max, py_max = closest_person_box
                    px_min, py_min = max(0, int(px_min)), max(0, int(py_min))
                    px_max, py_max = min(original_shape[1], int(px_max)), min(original_shape[0], int(py_max))
                    
                    if px_min < px_max and py_min < py_max:
                        person_roi = frame_rgb[py_min:py_max, px_min:px_max]
                        if person_roi.size > 0:
                            sq_frame, pad_l, pad_t = pad_frame_to_square(person_roi)
                            pose_res = self.mp_pose.process(sq_frame)
                            
                            if pose_res.pose_landmarks:
                                rel_landmarks = pose_res.pose_landmarks.landmark[11:25]
                                px_coords = [lm.x for lm in rel_landmarks]
                                py_coords = [lm.y for lm in rel_landmarks]
                                pm_x_min, pm_x_max = min(px_coords), max(px_coords)
                                pm_y_min, pm_y_max = min(py_coords), max(py_coords)
                                
                                x_range = max(pm_x_max - pm_x_min, 1e-6)
                                y_range = max(pm_y_max - pm_y_min, 1e-6)
                                
                                data = []
                                for lm in rel_landmarks:
                                    data.append((lm.x - pm_x_min) / x_range)
                                    data.append((lm.y - pm_y_min) / y_range)
                                    
                                bx_min, by_min, bx_max, by_max = ball_box
                                data.append((bx_min - pm_x_min) / x_range)
                                data.append((by_min - pm_y_min) / y_range)
                                data.append(max((bx_max - bx_min)/x_range, (by_max - by_min)/y_range))
                                
                                if len(data) == 31:
                                    pred = self.rf_model.predict([np.asarray(data)])
                                    detected_action = str(pred[0])

            # Logic to smooth multi-frame predictions into discrete actions
            if detected_action != "NONE":
                if current_action_type == detected_action:
                    # Continue current action
                    current_action_boxes.append(closest_person_box)
                else:
                    # Transition
                    if current_action_type != "NONE" and current_action_start is not None:
                        # Append the finished action
                        results.append({
                            "id": f"action_{len(results)}",
                            "type": current_action_type,
                            "start_ms": current_action_start,
                            "end_ms": timestamp_ms,
                            # Provide the median/average box or the last box for focus
                            "player_box": [float(x) for x in current_action_boxes[len(current_action_boxes)//2]],
                            "player_id": "Unknown",
                            "confidence": 0.8
                        })
                    current_action_type = detected_action
                    current_action_start = timestamp_ms
                    current_action_boxes = [closest_person_box]
            else:
                if current_action_type != "NONE" and current_action_start is not None:
                    duration = timestamp_ms - current_action_start
                    # Only register if it lasted a few frames (e.g. at least 100ms) to avoid random noise flashes
                    if duration > 100:
                        results.append({
                            "id": f"action_{len(results)}",
                            "type": current_action_type,
                            "start_ms": current_action_start,
                            "end_ms": timestamp_ms,
                            "player_box": [float(x) for x in current_action_boxes[len(current_action_boxes)//2]],
                            "player_id": "Unknown",
                            "confidence": 0.8
                        })
                    current_action_type = "NONE"
                    current_action_start = None
                    current_action_boxes = []
                    
            frame_idx += 1
            # Fire callback every 5 % of total frames
            if progress_callback and total_frames > 0:
                step = max(1, int(total_frames * 0.05))
                if frame_idx % step == 0:
                    progress_callback(frame_idx, total_frames)

        cap.release()
        
        # Flush the last action if any
        if current_action_type != "NONE" and current_action_start is not None:
            results.append({
                "id": f"action_{len(results)}",
                "type": current_action_type,
                "start_ms": current_action_start,
                "end_ms": (frame_idx / fps) * 1000.0,
                "player_box": [float(x) for x in current_action_boxes[len(current_action_boxes)//2]],
                "player_id": "Unknown",
                "confidence": 0.8
            })

        return {
            "total_frames": total_frames,
            "fps": fps,
            "actions": results
        }
