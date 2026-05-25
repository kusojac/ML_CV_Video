# Podręcznik Użytkownika — Volleyball Action Analytics Platform

Witaj w podręczniku użytkownika platformy **Volleyball Action Analytics**. System łączy nowoczesny frontend stacjonarny zbudowany w technologii **Flutter** z potężnym silnikiem analizy wideo opartym na modelach sztucznej inteligencji i wizji komputerowej (Python/FastAPI).

Aplikacja pozwala na importowanie nagrań meczów siatkarskich, automatyczne wykrywanie zawodników i piłki, klasyfikację kluczowych akcji (odbicie, wystawa, atak) oraz precyzyjną edycję i analizę taktyczną z wykorzystaniem trybu powiększenia (Focus Mode/PiP), pod-akcji oraz playlist.

---

## 🏗️ Architektura Systemu

System działa w architekturze klient-serwer uruchamianej lokalnie na Twoim komputerze:
1. **Backend (Python / FastAPI):** Uruchamia potok analizy komputerowej (YOLO dla piłki i ludzi, MediaPipe do estymacji pozycji ciała, Scikit-learn Random Forest do klasyfikacji cech biomechanicznych).
2. **Frontend (Flutter Desktop):** Aplikacja okienkowa dla systemu Windows, odpowiedzialna za odtwarzanie wideo, wizualizację detekcji, interaktywną oś czasu oraz edycję bazy danych zdarzeń.

---

## 🚀 Wymagania i Instalacja

### 1. Wymagania Wstępne
- **Python 3.10+** (z zainstalowanym narzędziem `pip`)
- **Flutter SDK** (kanał `stable`, skonfigurowany pod Windows Desktop)
- **Windows Developer Mode (Tryb Dewelopera):** Wymagany do prawidłowego działania dowiązań symbolicznych (symlinks) w kompilacji Flutter. Włącz go w: *Ustawienia systemu Windows -> Prywatność i bezpieczeństwo -> Dla deweloperów -> Tryb dewelopera*.

### 2. Krok po kroku: Uruchomienie Backendu (FastAPI)
Backend ładuje modele uczenia maszynowego w formatach ONNX i TFLite. Uruchomienie trwa zwykle ok. 10–15 sekund.

1. Otwórz terminal (PowerShell lub CMD).
2. Przejdź do folderu `backend`:
   ```powershell
   cd C:\Users\kusoj\Desktop\Projekty\GoGoShawk\VideoMobile4Sport\ML_CV_Video\VolleyballApp\backend
   ```
3. Aktywuj wbudowane środowisko wirtualne (venv):
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```
   > [!TIP]
   > Jeśli PowerShell zgłosi błąd uprawnień do uruchamiania skryptów (*"untrusted publisher"*), wpisz `R` (uruchom raz) lub `A` (zawsze).
4. Zainstaluj biblioteki (tylko za pierwszym razem):
   ```powershell
   pip install -r requirements.txt
   ```
5. Uruchom serwer API za pomocą `uvicorn`:
   ```powershell
   uvicorn main:app --reload --host 127.0.0.1 --port 8001
   ```
   *Alternatywa (bez aktywacji środowiska, bezpośrednie wywołanie Pythona z venv):*
   ```powershell
   .\venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8001
   ```

### 3. Krok po kroku: Uruchomienie Frontendu (Flutter Desktop)
1. Otwórz **drugie** okno terminala.
2. Przejdź do folderu `frontend`:
   ```powershell
   cd C:\Users\kusoj\Desktop\Projekty\GoGoShawk\VideoMobile4Sport\ML_CV_Video\VolleyballApp\frontend
   ```
3. Pobierz pakiety i skompiluj aplikację natywnie dla systemu Windows:
   ```powershell
   flutter run -d windows
   ```
Po chwili na ekranie pojawi się okno aplikacji graficznej.

---

## 📓 Środowisko Badawczo-Rozwojowe (R&D)

Backend wyposażony jest w notatnik Jupyter, który służy do testowania algorytmów wizji komputerowej niezależnie od interfejsu graficznego.

### Notatnik badawczy (`notebooks/analytics_sandbox.ipynb`)
Ten interaktywny notatnik dzieli cały proces analityczny (`engine.py`) na **10 odrębnych kroków**, umożliwiając podgląd pośrednich etapów:

| Krok | Funkcja | Opis |
| :---: | :--- | :--- |
| **1** | Konfiguracja | Importy niezbędnych bibliotek i ścieżek projektowych. |
| **2** | Modele | Ładowanie YOLOv8 (detekcja piłki/ludzi), MediaPipe (szkielet) oraz Random Forest. |
| **3** | Ustawienia | Wybór pliku wideo `.mp4` i parametrów progowych. |
| **4** | Wczytywanie | Ekstrakcja wybranej klatki wideo i konwersja przestrzeni barw. |
| **5** | Detekcja piłki | Wykrywanie piłki za pomocą dedykowanego modelu YOLO z wizualizacją. |
| **6** | Detekcja graczy | Wykrywanie wszystkich postaci na boisku (model COCO). |
| **7** | Asocjacja | Wskazanie gracza znajdującego się najbliżej piłki w danej chwili. |
| **8** | Szkielet | Uruchomienie MediaPipe Pose na wyciętym obszarze (ROI) zawodnika. |
| **9** | Klasyfikacja | Ekstrakcja 31 cech geometrycznych szkieletu i klasyfikacja akcji (Bump/Set/Attack). |
| **10** | Podsumowanie | Generowanie ostatecznego rysunku z naniesionymi ramkami detekcji i etykietami. |

### Zarządzanie wersjami notatników
Aby zapisać stan eksperymentów i nie nadpisywać pliku roboczego, możesz wyeksportować notatnik z unikalnym tagiem:
```powershell
python sync_notebook.py --tag moja_proba_ataku
```
Skrypt wygeneruje plik w folderze `notebooks/versions/` ze znacznikiem czasu i podanym tagiem.

---

## 🛠️ Funkcjonalności Aplikacji (GUI)

### 1. Zarządzanie Projektami (Project Manager)
- Ekran główny pozwala na importowanie nowych wideo (`Import Video`). Dane o plikach są zapisywane na stałe na dysku za pomocą pamięci lokalnej.
- Po wejściu w dany film można kliknąć przycisk **„Analizuj wideo” (Analyze Video)** na górnym pasku.

### 2. Automatyczna Analiza AI (Job Runner)
- Po uruchomieniu analizy backend przetwarza wideo klatka po klatce.
- Na frontendzie wyświetla się **pasek postępu w procentach (%)** oraz **czas pozostały do końca (ETA)**.
- Wyniki analizy są zapisywane w pliku JSON o nazwie `<nazwa_pliku>_analysis.json` obok wideo.

### 3. Interaktywna Oś Czasu (Timeline)
- Znajduje się na dole odtwarzacza wideo. Prezentuje rozkład czasowy wykrytych akcji siatkarskich, oznaczonych odpowiednimi kolorami:
  - 🟢 **SET (Wystawa)** — kolor zielony
  - 🔵 **BUMP (Odbicie dolne)** — kolor morski/turkusowy
  - 🔴 **ATTACK / SPIKE (Atak)** — kolor czerwony
  - 🟣 **Inne akcje (SERVE, BLOCK, DIG itp.)** — kolor fioletowy/szary
- **Zoom osi czasu:** Suwak powiększenia pozwala na precyzyjne rozciągnięcie skali czasu w celu analizowania akcji trwających ułamki sekund.
- **Przewijanie timeline (Scroll):** Przy włączonym powiększeniu (Zoom) możesz łatwo przewijać oś czasu w poziomie za pomocą gestu lub paska przewijania, aby dotrzeć do interesującego Cię fragmentu.

### 4. Tryb Focus (Obraz w Obrazie - PiP)
Kliknięcie na dowolne zdarzenie na liście akcji otwiera dodatkowe, ruchome okienko **Focus Mode** (Picture-in-Picture) w prawym górnym rogu odtwarzacza.
- Okno to wyświetla w czasie rzeczywistym powiększony kadr (crop) wycięty wokół zawodnika wykonującego daną akcję.
- Okno Focus posiada specjalne **uchwyty do zmiany rozmiaru** (w prawym dolnym rogu) oraz **uchwyty do przesuwania** (na górnej ramce). Pozwala to dopasować widok PiP do ekranu.

### 5. Obsługa Wielu Punktów Focus (Multiple Player Focus)
Jedna akcja siatkarska często angażuje więcej niż jednego zawodnika (np. blokujący i atakujący). System pozwala na dodawanie wielu celów focus dla pojedynczego zdarzenia:
- W panelu **„Śledzenie akcji (PIP)”** na dole prawego paska bocznego możesz zobaczyć listę przypisanych celów focus.
- W trybie edycji (`Edit Mode`) możesz kliknąć **„Dodaj”**, aby wskazać kolejnego gracza na ekranie.
- Możesz zmienić nazwę obszaru śledzenia, przypisać mu unikalny numer zawodnika (`Player ID`) lub usunąć zbędne kadry.
- Kliknięcie na okrągły przełącznik przy danym punkcie focus natychmiast przełącza aktywny podgląd PiP na tego zawodnika.

### 6. Obsługa Pod-Akcji (Sub-Action Support)
Pod-akcje umożliwiają tworzenie struktury hierarchicznej wewnątrz jednej dłuższej wymiany (np. w ramach całej akcji `RALLY` możemy dodać kolejne etapy: przyjęcie `RECEIVE`, wystawa `SET` i atak `ATTACK`):
- Pod-akcje wyświetlają się wewnątrz głównej karty akcji na prawym panelu bocznym.
- Każda pod-akcja ma swój czas rozpoczęcia, czas zakończenia, przypisanego gracza oraz własne punkty kluczowe.
- W trybie edycji możesz dodawać nowe pod-akcje (klawisz `S` lub ikona plusa), edytować je oraz usuwać.

### 7. Punkty Kluczowe (Key Points)
Punkty kluczowe reprezentują kluczowe momenty (klatki) w czasie trwania danej akcji/pod-akcji (np. dokładny moment kontaktu dłoni z piłką).
- Wizualizowane są jako **żółte diamenty** na osi czasu.
- Możesz je dodawać klawiszem `K` lub przyciskiem w panelu.
- Każdy punkt kluczowy ma swój krótki opis (np. *„Kontakt z piłką”*, *„Wyskok”*) i pozwala na szybkie przeskoczenie odtwarzacza do wybranej klatki.

### 8. Playlista i Filtrowanie
- Listę akcji możesz sortować po czasie, typie, numerze zawodnika oraz pewności detekcji (confidence).
- **Filtrowanie:** Szybkie odfiltrowanie akcji po typie i numerze zawodnika pozwala skupić się np. tylko na atakach zawodnika nr 8.
- **Playlista:** Możesz zaznaczać pojedyncze akcje na liście, aby dodać je do aktywnej playlisty. W zakładce *Playlista* możesz uruchomić odtwarzanie wyciętych fragmentów w pętli. Playlista może zostać zapisana jako niezależny plik JSON będący artefaktem projektu.

---

## ⌨️ Skróty Klawiszowe

Wygodne sterowanie analizą wideo i edycją bez odrywania rąk od klawiatury:

| Klawisz | Funkcja | Szczegóły |
| :---: | :--- | :--- |
| <kbd>Spacja</kbd> | **Play / Pause** | Wstrzymuje i wznawia odtwarzanie głównego wideo. |
| <kbd>E</kbd> | **Przełącz Tryb Edycji** | Włącza lub wyłącza tryb edycji akcji. |
| <kbd>A</kbd> lub <kbd>N</kbd> | **Dodaj nową akcję** | Dodaje nową akcję w miejscu obecnej pozycji suwaka. Automatycznie włącza tryb edycji. |
| <kbd>S</kbd> | **Dodaj pod-akcję** | Dodaje pod-akcję do aktualnie zaznaczonej akcji głównej. |
| <kbd>K</kbd> | **Dodaj punkt kluczowy** | Wstawia punkt kluczowy (Key Point) do zaznaczonej akcji lub pod-akcji. |
| <kbd>Delete</kbd> / <kbd>Backspace</kbd> | **Usuń zaznaczony element** | Usuwa zaznaczoną akcję główną, pod-akcję lub punkt kluczowy (działa tylko w trybie edycji). |
| <kbd>Strzałka w lewo</kbd> | **Cofnij o 500 ms** | Cofa wideo o pół sekundy. **Trzymaj <kbd>Shift</kbd>**, aby cofnąć o 5 sekund. |
| <kbd>Strzałka w prawo</kbd> | **Przejdź o 500 ms w przód** | Przesuwa wideo o pół sekundy. **Trzymaj <kbd>Shift</kbd>**, aby przesunąć o 5 sekund. |
| <kbd>Strzałka w górę</kbd> | **Poprzednia akcja** | Przechodzi do poprzedniego zdarzenia na liście. |
| <kbd>Strzałka w dół</kbd> | **Następna akcja** | Przechodzi do kolejnego zdarzenia na liście. |

---

> [!IMPORTANT]
> **Zapisywanie zmian:** Wszelkie modyfikacje wykonane w trybie edycji (dodawanie akcji, zmiana pozycji ramek, modyfikowanie punktów focus) powodują pojawienie się żółtego wskaźnika przy ikonie zapisu. Użyj menu zapisu w prawym górnym rogu ekranu, aby zapisać zmiany do pliku JSON (`Zapisz obok wideo` lub `Zapisz jako...`).
