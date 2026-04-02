import os
import re
import json
import argparse
from datetime import datetime

def create_notebook(tag=None):
    engine_path = "engine.py"
    if not os.path.exists(engine_path):
        print(f"Brak pliku {engine_path}!")
        return

    with open(engine_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # 1. Wyciągnięcie importów
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
                # Oczyszczanie "self."
                cln = line.replace("self.", "")
                # Usuwanie wcięć (8 spacji zwykle dla ciała __init__)
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

    # Oczyszczanie procesu z pętli while
    process_single_frame = []
    in_loop = False
    for line in process_lines:
        if "while cap.isOpened():" in line:
            in_loop = True
            continue
        
        if in_loop:
            # Pomiń return we while (choć go tam raczej nie ma w połowie)
            if "if not ret:" in line or "break" in line:
                pass
            
            # Właściwy kod klatki - odcięcie 1 tabulacji/4 spacji
            if line.startswith("            "):
                process_single_frame.append(line[12:])
            elif line.startswith("\t\t\t"):
                process_single_frame.append(line[3:])
            else:
                pass

    # Komponowanie Notebook'a
    cells = []
    
    def add_md(text):
        cells.append({
            "cell_type": "markdown",
            "metadata": {},
            "source": [text]
        })
    
    def add_code(lines_list):
        source = []
        for l in lines_list:
            source.append(l)
        cells.append({
            "cell_type": "code",
            "execution_count": None,
            "metadata": {},
            "outputs": [],
            "source": source
        })

    add_md("# Środowisko R&D do analityki (Zsynchronizowane z engine.py)")
    
    import_cell = imports + ["import matplotlib.pyplot as plt\n", "\n", 'models_dir = "./models"\n']
    add_code(import_cell)

    add_md("### Inicjalizacja modeli (wydzielone z `__init__`)")
    add_code(init_lines)

    add_md("### Wczytanie wideo z dysku\nUstaw poniżej poprawną ścieżkę do wideo roboczego, które chcesz analizować krok po kroku.")
    add_code([
        'video_path = "../MLCV test.mp4" # <--- ZMIEN TO W RAZIE POTRZEBY\n',
        'cap = cv2.VideoCapture(video_path)\n',
        'fps = cap.get(cv2.CAP_PROP_FPS)\n',
        '# Przewinięcie do wybranej klatki (np. klatka 100):\n',
        '# cap.set(cv2.CAP_PROP_POS_FRAMES, 100)\n'
    ])
    
    add_md("### Wyodrębnienie jednej klatki klatki (Uruchawiaj tą komórkę aby przejść do kolejnej)")
    add_code([
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
    ])

    add_md("### Logika `process_video` z `engine.py` (Zastosowane dla jednej klatki `frame_rgb`)")
    add_code(process_single_frame)

    # Konstrukcja JSONa Notebook'a
    notebook = {
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

    # Tworzenie folderów
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
