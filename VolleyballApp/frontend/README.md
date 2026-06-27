# Volleyball Action Analytics Platform — Frontend

This is the desktop frontend for the **Volleyball Action Analytics Platform**, built using **Flutter Desktop** for Windows. It provides a rich graphical interface to manage video analysis projects, interact with a frame-level timeline, and refine automatically detected volleyball actions.

---

## 🚀 How to Run the Frontend

1. **Prerequisites**:
   - Install the **Flutter SDK** (stable channel, with Windows desktop support enabled).
   - Enable **Developer Mode** in Windows Settings (*Settings -> Privacy & security -> For developers -> Developer Mode*).
   - Ensure the FastAPI Backend is running (see the [Main README](../README.md) for backend instructions).

2. **Navigate to this folder**:
   ```bash
   cd VolleyballApp/frontend
   ```

3. **Get dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the desktop app**:
   ```bash
   flutter run -d windows
   ```

---

## 📂 Key Architecture & Screens

The application is structured inside the [lib](lib) directory:
- **`lib/screens/home_screen.dart`**: Project manager interface where you can browse/import videos.
- **`lib/screens/video_analysis_screen.dart`**: Main workspace featuring the video player, overlay bounding boxes, player Focus Mode (PiP), multiple player target switches, and the interactive timeline.
- **`lib/screens/artifact_edit_screen.dart`**: Dedicated interface for managing sub-actions, custom key frame points, and playlists.
- **`lib/services/`**: Services managing communication with the Python/FastAPI backend and native disk persistence.

---

## 📖 Learn More

- For full installation and execution details, refer to the [Main README](../README.md).
- To read the detailed Polish guide on application features, shortcuts, and architecture, check the [User Guide](../USER_GUIDE.md).
