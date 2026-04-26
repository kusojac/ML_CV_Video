# VolleyballApp TODO List

Poniżej znajduje się lista zaplanowanych zadań i przyszłych usprawnień dla systemu analizy siatkarskiej.

## ⚙️ Backend (AI & API)

- [ ] **Śledzenie Zawodników i Re-Identyfikacja (Re-ID)**
  - Aktualnie system nie śledzi unikalnego identyfikatora zawodnika między klatkami/scenami (wszystkie akcje otrzymują `playerId: "Unknown"`). 
  - Wymagana implementacja algorytmu śledzącego (np. DeepSORT, BoT-SORT) aby powiązać wykrytych graczy ze stałymi numerami ID na przestrzeni całego meczu.
  - Opcjonalnie: Dodanie detekcji numerów na koszulkach (OCR) celem automatycznego przypisywania prawidłowych numerów zawodników.

- [ ] **Detekcja Linii Boiska i Rzutowanie Perspektywy (Homografia)**
  - Należy dodać moduł estymacji układu boiska siatkarskiego z kamery (wykrywanie 4 rogów i linii końcowych).
  - Po wykryciu rogów, wykorzystać rzutowanie perspektywiczne (`cv2.warpPerspective` / homography) do przeliczenia pozycji graczy (`playerBox`) na płaską płytę boiska 2D. 
  - Pozwoli to na generowanie heat-map taktycznych pokazujących np. strefy ataków.

- [ ] **Zarządzanie Zadaniami i Persystencja (Redis/Celery/DB)**
  - Obecnie backend przechowuje zadania analizy (`analysis_jobs`) jako słownik w pamięci podręcznej (in-memory state w FastAPI).
  - Przy skalowaniu aplikacji lub restarcie serwera backendu (`uvicorn`) podczas długiej analizy, ulega ona zniszczeniu, a dane o ETA i progresie przepadają.
  - Zastąpić in-memory słownik kolejką np. Redis lub bazą danych (SQLite/PostgreSQL) śledzącą asynchroniczne procesy `job_id`.

## 🖥️ Frontend (Flutter)

- [ ] **Poprawa Wydajności Edytora Akcji**
  - Opcjonalne optymalizowanie odświeżania odtwarzacza przy masowym odświeżaniu wielu małych markerów na długim `timeline`.
- [ ] **Widok 2D Boiska**
  - (Po wdrożeniu homografii na backendzie) - stworzenie nowego widgetu wyświetlającego płaskie boisko 2D oraz przerysowanie lokalizacji `X, Y` zawodnika dla wyselekcjonowanej akcji w celu precyzyjniejszej weryfikacji gry. 
- [x] **Zmiana uchwytów wskaźników**
  - Zmiana uchwytów wskaźników w edytorze akcji na bardziej atrakcyjne wizualnie i czytelne.
  - w aktualnej wersji uchwyty są kwadratowe i słabo widoczne.
  - należy zmienić kształt w skaźnika w sytuacji gdy najeżdżamy na okienko pip w celu zmiany rozmiaru lub przeniesienia go. W okolicy aktualnych obszarów przsuwania i na rogu okienka przy uchwycie zmiany rozmiaru. Dodaj też atrakcyjnie wizualnie uchwyty poruszania i zmiany rozmiaru.
- [x] **Dodanie uchwytów do zmiany rozmiaru okienka fokus w trybie edycji akcji.**
  - Dodanie uchwytów do zmiany rozmiaru okienka fokus w trybie edycji akcji. W aktualnej wersji okienko fokus nie ma uchwytów do zmiany rozmiaru.
- [ ] **Edycja zawodnika**
  - w edytorze akcji, w panelu musi być możliwość dodania nowego wskaźnika dla danego zawodnika (wybieramy akcję, wybieramy zawodnika, dodajemy wskaźnik).
  - w edytorze akcji, w panelu musi być możliwość edycji numeru zawodnika, z którym ta akcja została wykonana.
- [ ] **Dodanie przesuwania timeline w sytuacji gdy jest zoom i chcemy przejść do końca timeline.**
  - Należy dodać możliwość przesuwania timeline w sytuacji gdy jest zoom i chcemy przejść do końca timeline lub do momentu który nie jest widoczny na ekranie. 
- [ ] **Zmiana wskaźnika akcji na timeline.**
  - W miejscu gdzie jest wskaźnik akcji na timeline, gdy jest zoom i chcemy przesunąć się na timeline, wskaźnik się przesuwa za ręką. Zamiast tego wskaźnik powinien być stały i nie powinien się przesuwać za ręką. (najlepiej tak aby wskaźnik na timeline podążał za ręką wskaźnika)
- [ ] **Dodanie możliwości dodawania akcji z poziomu odtwarzacza.**
  - Dodanie możliwości dodawania akcji z poziomu odtwarzacza.
- [ ] **Dodanie możliwości edycji akcji z poziomu odtwarzacza.**
  - Dodanie możliwości edycji akcji z poziomu odtwarzacza.
- [ ] **Dodanie możliwości usuwania akcji z poziomu odtwarzacza.**
  - Dodanie możliwości usuwania akcji z poziomu odtwarzacza.
- [x] **Dodanie uchwytów do zmiany rozmiaru okienka fokus w trybie edycji akcji.**
  - Dodanie uchwytów do zmiany rozmiaru okienka fokus w trybie edycji akcji. W aktualnej wersji okienko fokus nie ma uchwytów do zmiany rozmiaru.
- [ ] **Zoptymalizowanie odświeżania okienek w trybie edycji akcji**
  - W trybie edycji akcji, gdy jest wiele wskaźników, odświeżanie okienek jest powolne. Należy zoptymalizować odświeżanie okienek.
