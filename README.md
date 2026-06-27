# VideoMobile4Sport — Volleyball ML & CV Video Analysis

This repository contains machine learning models, computer vision pipelines, and desktop applications for automated volleyball video analysis. 

The project is structured into two main sub-applications:

---

## 📂 Sub-Projects

### 1. 🏐 [Volleyball Action Analytics Platform (Full App)](VolleyballApp)
A complete desktop application combining:
- **Backend ([VolleyballApp/backend](VolleyballApp/backend))**: Python FastAPI continuous daemon running YOLO ball/player tracking, MediaPipe Pose estimation, and Scikit-learn Random Forests to recognize volleyball actions.
- **Frontend ([VolleyballApp/frontend](VolleyballApp/frontend))**: Flutter desktop application for Windows, featuring project management, interactive frame-level timeline, draggable/resizable player Focus Mode (PiP), sub-actions, key frame tags, and playlist exports.
- **Detailed Documentation**:
  - [VolleyballApp README](VolleyballApp/README.md)
  - [Polish User Guide](VolleyballApp/USER_GUIDE.md)

### 2. 🤖 [Real-Time Volleyball Action Detection (R&D & Web App)](Volleyball-Action-Detection)
An R&D pipeline and a light web interface featuring:
- Custom-trained YOLO11 models for volleyball detection.
- Classical machine learning models trained on pose coordinate features.
- Streamlit-based web application demo to upload media and visualize detections in real-time.
- **Detailed Documentation**:
  - [Volleyball-Action-Detection README](Volleyball-Action-Detection/README.md)

---

## 🚀 Getting Started

Please navigate into either of the sub-folders above and follow their respective instruction guides to run the models or the interactive applications.
