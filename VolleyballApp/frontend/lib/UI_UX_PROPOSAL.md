# Propozycja zmian UI/UX dla VolleyballApp

## Analiza podobnych rozwiązań na rynku

Zbadano podobne aplikacje do analizy wideo sportowego, takie jak:
1. **Catapult Pro Video / XOS Digital** (wiodące rozwiązania profesjonalne).
2. **Nacsport / KlipDraw** (rozbudowane oprogramowanie do rysowania po wideo).
3. **Hudl** (popularne, używane powszechnie na różnych szczeblach rozgrywek).
4. **Dartfish** (klasyczne narzędzie znane z dokładnej analizy biomechaniki).

Wyróżniające cechy najlepszych rozwiązań to:
- Przejrzysty układ (wideo w centrum, klipy z boku, osie czasu na dole).
- Zintegrowane narzędzia "telestration" (rysowania) w tym samym widoku (np. KlipDraw).
- Elastyczność - możliwość odłączania paneli (np. przeniesienia wideo na drugi monitor).
- Zunifikowane i rozbudowane skróty klawiaturowe do sterowania odtwarzaniem bez użycia myszy.
- Graficzna, interaktywna oś czasu zamiast prostej listy lub paska.

## Wybrane najlepsze zmiany w UI/UX dla tego projektu

### 1. Przebudowa odtwarzacza wideo i osi czasu (Timeline)
Obecne rozwiązanie wykorzystuje prosty suwak postępu `LinearProgressIndicator` (lub domyślny z pakietów). Należy zastąpić go interaktywną, wielościeżkową osią czasu (Timeline).
*   **Wielowarstwowość:** Na dole ekranu główny pasek odtwarzania powinien wizualnie zaznaczać wystąpienia akcji w formie poziomych bloków, kodowanych kolorami dla każdego zawodnika lub typu akcji.
*   **Zoom i przewijanie:** Możliwość przybliżania szczegółowych fragmentów i płynnego przewijania.
*   **Scrubbing:** Trzymanie myszy na osi czasu powinno płynnie przesuwać klatki wideo do przodu/tyłu. Oznacza to implementację niestandardowego suwaka odtwarzania powiązanego z pozycją Media Kit.

### 2. Zaawansowane możliwości narzędzia Focus (Picture-in-Picture)
Projekt wprowadził opcję "Focus", ale na tle rynkowych standardów można ją ulepszyć:
*   **Efekt lupy:** Zamiast okienka Picture-in-Picture z całym wideo, narzędzie powinno pozwalać na dodanie okręgu/lupy powiększającego akcję (obszar uderzenia), lub zatrzymanie obrazu (freeze-frame) przy konkretnym momencie ataku.
*   **Telestracje:** Dodanie panelu narzędzi po lewej stronie do rysowania strzałek lub kątów bezpośrednio na wideo, co jest standardem (np. w KlipDraw).

### 3. Poprawa czytelności list (Puste Stany - Empty States)
Obecnie aplikacja posiada już niektóre "empty states", ale należy upewnić się, że *każda* pusta lista w systemie (brak playlist, brak projektów) posiada ilustrację graficzną oraz wyraźne Call To Action (przycisk wywołujący akcję). Stany puste dla `_filteredArtifacts.isEmpty` lub pustych projektów na ekranie domowym powinny mieć estetyczne wektorowe obrazki lub bardziej rozbudowane ikony oraz przyciski takie jak "Utwórz projekt" zamiast tylko suchej wiadomości.

### 4. Spójność nazewnictwa i ikonek (Dostępność / Accessibility)
Jak wynika z zapisów `.Jules/palette.md`, wszystkie `IconButton` muszą mieć właściwość `tooltip`. Należy zapewnić pełną nawigację klawiaturową po najważniejszych elementach ekranu VideoAnalysis.

### 5. Skróty klawiaturowe (Keybindings)
Dodanie obsługi zdarzeń klawiatury dla całego ekranu `VideoAnalysisScreen`. W programach jak Nacsport używa się:
*   `Spacja` - Play/Pause
*   `Strzałka w lewo/prawo` - Skok o klatkę (-/+ 1 frame) lub o 1 sekundę.
*   `J`, `K`, `L` - Klasyczne skróty edytorów wideo: J (do tyłu), K (pauza), L (do przodu ze zwiększaniem prędkości).

## Wdrożone szybkie usprawnienia UX/A11Y (Dostępność)
W ramach tej iteracji wprowadzono również drobne, ale istotne naprawy:
- **Tłumaczenia interfejsu (I18n):** Przycisk z tekstem "Analyze Video" został przetłumaczony na "Analizuj wideo" w `video_analysis_screen.dart`, ujednolicając interfejs, który w większości używa języka polskiego.
- **Dodanie Tooltipów na przyciskach:** Zgodnie z dobrymi praktykami UX oraz logami w `.Jules/palette.md`, na interaktywnych ikonach bez tekstu wymagane są etykiety dla screen-readerów. Dodano właściwość `tooltip` do `PopupMenuButton` w oknie projektu oraz `IconButton` przy usuwaniu zawodnika. Pomaga to zrozumieć dostępne akcje osobom z mniejszym doświadczeniem w obsłudze aplikacji.
