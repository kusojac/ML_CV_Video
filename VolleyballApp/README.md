# Volleyball Action Analytics Platform

A seamless, real-time desktop application built with a **Flutter** frontend and **Python/FastAPI** backend for automated volleyball video analysis. The system detects the ball, players, and key actions (Bump, Set, Attack) to enrich videos with metadata and specialized interfaces like "Focus Mode."

## 🚀 How to Run the Application

The project is split into two independent runtimes that communicate locally on your machine. You must run both the **Backend** and the **Frontend** simultaneously.

### 1. Prerequisites
- **Python 3.10+** (Ensure you have `pip` installed)
- **Flutter SDK** (Channel stable, specifically checked for Windows Desktop)
- **Developer Mode (Windows):** For Flutter Windows compilation plugins to build via symlinks, please ensure Developer Mode is enabled in Windows Settings -> Privacy & security -> For developers -> Developer Mode.

---

### Step 1: Start the Python Backend API
The backend handles the heavyweight Computer Vision models (YOLO, MediaPipe, Scikit-learn Random Forests).

1. Open a new Terminal (PowerShell or CMD).
2. Navigate to the `backend` folder:
   ```bash
   cd C:\Users\kusoj\Desktop\Projekty\GoGoShawk\VideoMobile4Sport\ML_CV_Video\VolleyballApp\backend
   ```
3. Activate the **backend** virtual environment (located inside `backend\venv\`):
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```
   > **⚠️ Important:** Run this from inside the `backend\` folder. `uvicorn` and all CV dependencies are installed in `backend\venv\`, not the root `.venv`. If PowerShell shows an *"untrusted publisher"* prompt, type `R` to run once or `A` to always allow.
4. Install dependencies (first time only):
   ```bash
   pip install -r requirements.txt
   ```
5. Run the FastAPI server using `uvicorn`:
   ```bash
   uvicorn main:app --reload --host 127.0.0.1 --port 8001
   ```
*You should see output indicating that `Uvicorn running on http://127.0.0.1:8001` is active.* Startup takes ~10–15 seconds while ONNX, TFLite, and sklearn models load. Let this window stay open in the background.

> **Troubleshooting — `uvicorn: not recognized`:** This means the venv is not activated. Make sure you ran `.\venv\Scripts\Activate.ps1` from **inside the `backend\` folder** first. The root `.venv` does not contain `uvicorn`.
>
> If `Activate.ps1` doesn't work in your terminal (e.g. non-interactive PowerShell), use this alternative that calls the venv's Python directly — **no activation needed**:
> ```powershell
> .\venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8001
> ```

---

### Step 2: Start the Flutter Desktop Frontend
The frontend presents a project manager interface where you can browse and play annotated video data.

1. Open a **second**, separate Terminal.
2. Navigate to the `frontend` directory:
   ```bash
   cd C:\Users\kusoj\Desktop\Projekty\GoGoShawk\VideoMobile4Sport\ML_CV_Video\VolleyballApp\frontend
   ```
3. Fetch the plugins and build the desktop app natively:
   ```bash
   flutter run -d windows
   ```
*This command will launch the compiled standalone `.exe` GUI window on your Windows machine.*

---

## 📓 R&D: Analiza Klatka po Klatce — Jupyter Notebook

Backend posiada gotowy notatnik Jupyter (`notebooks/analytics_sandbox.ipynb`) do interaktywnego testowania i ulepszania silnika analitycznego **niezależnie** od aplikacji Flutter/FastAPI.

### Czym jest notatnik?
Notatnik rozkłada logikę `engine.py` na **10 oddzielnych kroków**, które możesz wykonywać jeden po drugim:

| Krok | Co robi |
|------|---------|
| 1 | Importy bibliotek i konfiguracja ścieżek |
| 2 | Inicjalizacja modeli (YOLO, MediaPipe, RandomForest) |
| 3 | Wybór pliku wideo i ustawienie progów detekcji |
| 4 | Wczytanie i podgląd wybranej klatki |
| 5 | Detekcja piłki (YOLO VB) z wizualizacją |
| 6 | Detekcja zawodników (YOLO COCO) z wizualizacją |
| 7 | Wybór najbliższego zawodnika do piłki |
| 8 | Estymacja pozy (MediaPipe) na wyciętym ROI |
| 9 | Ekstrakcja 31 cech i klasyfikacja akcji (RandomForest) |
| 10 | Pełna wizualizacja wyników na klatce |

Bonus: komórka do **masowego testowania** N klatek z tabela wyników.

### Jak uruchomić?

```powershell
# 1. Przejdź do folderu backend (z aktywnym venv)
cd VolleyballApp\backend
.\venv\Scripts\Activate.ps1

# 2. Zainstaluj zależności (jeśli jeszcze nie)
pip install -r requirements.txt

# 3. Uruchom Jupyter
jupyter notebook
```
Otwórz w przeglądarce: `notebooks/analytics_sandbox.ipynb`

> **Zmień ścieżkę wideo** w Kroku 3 na własny plik `.mp4` przed uruchomieniem kolejnych komórek.

---

### Wersjonowanie i synchronizacja

Chcesz zapisać wersję roboczą notatnika lub zsynchronizować go z najnowszym `engine.py`? Użyj skryptu:

```powershell
# Generuje nową wersję notatnika z tagiem (np. "test_nowy_prog")
python sync_notebook.py --tag test_nowy_prog
```

Wygenerowany plik trafi do: `notebooks/versions/analytics_test_nowy_prog_YYYYMMDD_HHMMSS.ipynb`

Możesz mieć wiele wersji roboczych:
- `analytics_sandbox.ipynb` — bieżące pole robocze (edytuj do woli)
- `notebooks/versions/` — archiwum historycznych wersji ze znacznikiem daty


## 🛠 Features

- **Project Manager:** Click `Import Video` to add `.mp4` or `.mov` files from your disk. Files stay cached natively via `shared_preferences`.
- **Automated AI Run:** Open an imported video and select "Analyze Video." The Flutter app will quietly ping the continuous python daemon instance, awaiting results without freezing your CPU.
- **Dynamic Bounding Boxes & Triggers:** The Python engine automatically runs YOLO tracking, and whenever the ball changes sudden directional speed, it queries MediaPipe to recognize pose joints and determines the Action Event.
- **Player Focus Mode:** Once analysis finishes, simply clicking on an event like **'Set'** will engage a 200x200 crop overlay specifically fixed onto that individual player utilizing dynamic scale transformation over the base video player.
- **Corrections Toolkit:** Filter by player jersey (auto-inferred or tracked) or action type to clean false positives, simply hit edit to fix a tag!

<br>

*Built referencing the 5VREAL Project research methodology.*
