<<<<<<< HEAD:.Jules/palette.md
## 2024-05-24 - Consistent Empty State Empty Filters CTA
**Learning:** Some lists show 'Clear filters' natively on the empty state when filters are active, but incorrectly show generic fallbacks or misaligned code structures without clearing filters correctly.
**Action:** When creating empty states, standardizing clear filter actions is important.
=======
## 2024-05-19 - Empty State Structure
**Learning:** Generic text fallbacks for empty states increase user friction. Using structured empty states with descriptive icons, text, and specific CTA buttons corresponding to standard user actions (e.g. adding items or clearing filters) significantly improves discoverability.
**Action:** When creating lists or grids that may be empty, always conditionally render a structured widget providing context and clear actionable steps rather than relying on generic 'Empty list' text.

## 2024-05-20 - Empty State Improvements
**Learning:** Replacing plain text empty states with visually distinct layouts containing actionable icons and buttons significantly reduces friction for first-time users. In this app, many empty lists (like projects or artifacts) default to plain Text widgets.
**Action:** Always scan for `isEmpty` conditionals in lists or grids and replace generic `Text` fallbacks with structured empty states featuring a clear Call-To-Action.

## 2024-05-20 - Missing Tooltips on IconButtons
**Learning:** Icon-only interactive elements (`IconButton`) lacking `tooltip` or `semanticLabel` properties are inaccessible to screen readers and offer poor UX without hover text.
**Action:** Always verify `IconButton` implementations include a localized `tooltip` attribute to provide context and ensure accessibility compliance.

## 2024-05-24 - Actionable Empty States in Project Artifacts
**Learning:** Dead-end empty states (like generic 'Brak zawodników' texts) create friction. Replacing them with structured Call-To-Action buttons (e.g., 'Dodaj zawodnika') guides users directly to the next logical step.
**Action:** Scan for isEmpty list conditionals and replace plain generic text fallbacks with structured layouts featuring explicit ElevatedButton.icon CTAs.

## 2025-06-14 - Empty State Contextual CTAs
**Learning:** Generic empty states without context or specific calls to action create user friction, particularly when the view is empty due to active filters.
**Action:** Always replace plain generic text fallbacks with structured empty states that include explicit Call-To-Action (CTA) buttons relevant to the user's workflow (e.g., 'Clear filters' if triggered by filters, or 'Add' if genuinely empty).

## 2026-05-24 - Empty State CTAs
**Learning:** Relying solely on textual instructions or AppBar icons in empty states creates unnecessary friction, as users must scan for actions elsewhere. Providing immediate, contextual Call-To-Action buttons directly inside the empty state significantly improves discoverability and usability.
**Action:** When creating or updating empty list/grid views (`isEmpty` blocks), always include explicitly visible `ElevatedButton` (or similar) Call-To-Action elements within the empty state layout to guide the user's next steps.

## 2026-05-24 - Actionable Empty States for Filtered Lists
**Learning:** Providing a dead-end empty state (like 'Brak projektów spełniających kryteria.') when a search/filter yields no results forces the user to manually seek out the search bar or clear filters button elsewhere.
**Action:** When an empty state is explicitly triggered by an active search query (e.g., `_searchController.text.isNotEmpty`), immediately provide a 'Clear filters' ('Wyczyść filtry') CTA within the empty state layout to allow users to quickly recover to the full list view. Ensure to re-invoke the filtering logic upon clearing the controller.

## 2026-05-26 - Actionable Empty States in Project Artifacts
**Learning:** Dead-end empty states (like generic 'Brak zawodników' texts) create friction. Replacing them with structured Call-To-Action buttons (e.g., 'Dodaj zawodnika') guides users directly to the next logical step.
**Action:** Scan for  list conditionals and replace plain generic text fallbacks with structured layouts featuring explicit  CTAs.
>>>>>>> main:.jules/palette.md
## 2024-05-18 - Improve Empty State Call-To-Action (CTA) Prominence
**Learning:** Generic text buttons in empty states (e.g., `TextButton.icon` for "Analyze Video" when no actions exist) lack visual weight, making the primary workflow less intuitive for users. Additionally, hardcoded English strings in a primarily localized interface degrade accessibility and consistency.
**Action:** Always upgrade primary actions in empty states to prominent CTA buttons (e.g., `ElevatedButton.icon` with brand colors) to guide the user, and ensure all user-facing text is correctly localized to the application's primary language (e.g., Polish).
