import os
import json
import argparse
from datetime import datetime

def _create_markdown_cell(text):
    return {
        "cell_type": "markdown",
        "metadata": {},
        "source": [text]
    }

def _create_code_cell(lines_list):
    return {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": list(lines_list)
    }

def _parse_engine_file(lines):
    imports = []
    init_lines = []
    process_lines = []
    
    state = "imports"
    for line in lines:
        if state == "imports":
            if line.startswith("class"):
                state = "class_def"
            elif line.strip() and not line.startswith("class"):
                imports.append(line)
        elif state == "class_def":
            if "def __init__" in line:
                state = "init"
            elif "def process_video" in line:
                state = "process"
        elif state == "init":
            if "def process_video" in line:
                state = "process"
            else:
                cln = line.replace("self.", "")
                if cln.startswith("        "):
                    cln = cln[8:]
                elif cln.startswith("\t\t"):
                    cln = cln[2:]
                init_lines.append(cln)
        elif state == "process":
            if "def " in line and not line.startswith("        def"):
                break # inna funkcja
            else:
                cln = line.replace("self.", "")
                process_lines.append(cln)

    return imports, init_lines, process_lines

def _clean_process_lines(process_lines):
    process_single_frame = []
    in_loop = False
    for line in process_lines:
        if "while cap.isOpened():" in line:
            in_loop = True
            continue
        
        if in_loop:
            if "if not ret:" in line or "break" in line:
                pass
            
            if line.startswith("            "):
                process_single_frame.append(line[12:])
            elif line.startswith("\t\t\t"):
                process_single_frame.append(line[3:])
            else:
                pass
    return process_single_frame

def _build_notebook_structure(cells):
    return {
        "cells": cells,
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3"
            },
            "language_info": {
                "codemirror_mode": {"name": "ipython", "version": 3},
                "file_extension": ".py",
                "mimetype": "text/x-python",
                "name": "python",
                "nbconvert_exporter": "python",
                "pygments_lexer": "ipython3",
                "version": "3.11.0"
            }
        },
        "nbformat": 4,
        "nbformat_minor": 5
    }

def create_notebook(tag=None):
    engine_path = "engine.py"
    if not os.path.exists(engine_path):
        print(f"Brak pliku {engine_path}!")
        return

    with open(engine_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    imports, init_lines, process_lines = _parse_engine_file(lines)
    process_single_frame = _clean_process_lines(process_lines)

    cells = []
    
    cells.append(_create_markdown_cell("# Środowisko R&D do analityki (Zsynchronizowane z engine.py)"))
    
    import_cell = imports + ["import matplotlib.pyplot as plt\n", "\n", 'models_dir = "./models"\n']
    cells.append(_create_code_cell(import_cell))

    cells.append(_create_markdown_cell("### Inicjalizacja modeli (wydzielone z `__init__`)"))
    cells.append(_create_code_cell(init_lines))

    cells.append(_create_markdown_cell("### Wczytanie wideo z dysku\nUstaw poniżej poprawną ścieżkę do wideo roboczego, które chcesz analizować krok po kroku."))
    cells.append(_create_code_cell([
        'video_path = "../MLCV test.mp4" # <--- ZMIEN TO W RAZIE POTRZEBY\n',
        'cap = cv2.VideoCapture(video_path)\n',
        'fps = cap.get(cv2.CAP_PROP_FPS)\n',
        '# Przewinięcie do wybranej klatki (np. klatka 100):\n',
        '# cap.set(cv2.CAP_PROP_POS_FRAMES, 100)\n'
    ]))
    
    cells.append(_create_markdown_cell("### Wyodrębnienie jednej klatki klatki (Uruchawiaj tą komórkę aby przejść do kolejnej)"))
    cells.append(_create_code_cell([
        "ret, frame = cap.read()\n",
        "if not ret:\n",
        "    print('Koniec wideo!')\n",
        "else:\n",
        "    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)\n",
        "    original_shape = frame.shape\n",
        "    plt.figure(figsize=(8,5))\n",
        "    plt.imshow(frame_rgb)\n",
        "    plt.title('Bieżąca klatka do analizy')\n",
        "    plt.axis('off')\n",
        "    plt.show()\n"
    ]))

    cells.append(_create_markdown_cell("### Logika `process_video` z `engine.py` (Zastosowane dla jednej klatki `frame_rgb`)"))
    cells.append(_create_code_cell(process_single_frame))

    notebook = _build_notebook_structure(cells)

    os.makedirs("notebooks", exist_ok=True)
    os.makedirs("notebooks/versions", exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    name = f"analytics_{timestamp}" if not tag else f"analytics_{tag}_{timestamp}"
    filename = f"notebooks/versions/{name}.ipynb"
    
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(notebook, f, indent=1, ensure_ascii=False)
        
    print(f"Notatnik pomyslnie zsynchronizowany i wygenerowany: {filename}")
    print("Mozesz go otworzyc komenda: jupyter notebook")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Synchronizuj logikę backendu do notatnika Jupyter.")
    parser.add_argument("--tag", type=str, help="Opcjonalny tag dla wersji (np. 'test_yolo')", default=None)
    args = parser.parse_args()
    create_notebook(args.tag)
