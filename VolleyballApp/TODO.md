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
