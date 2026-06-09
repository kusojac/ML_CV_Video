## 2024-05-20 - Empty State Improvements
**Learning:** Replacing plain text empty states with visually distinct layouts containing actionable icons and buttons significantly reduces friction for first-time users. In this app, many empty lists (like projects or artifacts) default to plain Text widgets.
**Action:** Always scan for `isEmpty` conditionals in lists or grids and replace generic `Text` fallbacks with structured empty states featuring a clear Call-To-Action.

## 2026-05-24 - Empty State CTAs
**Learning:** Relying solely on textual instructions or AppBar icons in empty states creates unnecessary friction, as users must scan for actions elsewhere. Providing immediate, contextual Call-To-Action buttons directly inside the empty state significantly improves discoverability and usability.
**Action:** When creating or updating empty list/grid views (`isEmpty` blocks), always include explicitly visible `ElevatedButton` (or similar) Call-To-Action elements within the empty state layout to guide the user's next steps.
## 2024-05-20 - Missing Tooltips on IconButtons
**Learning:** Icon-only interactive elements (`IconButton`) lacking `tooltip` or `semanticLabel` properties are inaccessible to screen readers and offer poor UX without hover text.
**Action:** Always verify `IconButton` implementations include a localized `tooltip` attribute to provide context and ensure accessibility compliance.

## 2026-05-26 - Actionable Empty States in Project Artifacts
**Learning:** Dead-end empty states (like generic 'Brak zawodników' texts) create friction. Replacing them with structured Call-To-Action buttons (e.g., 'Dodaj zawodnika') guides users directly to the next logical step.
**Action:** Scan for  list conditionals and replace plain generic text fallbacks with structured layouts featuring explicit  CTAs.

## 2024-05-24 - Actionable Empty States in Project Artifacts
**Learning:** Dead-end empty states (like generic 'Brak zawodników' texts) create friction. Replacing them with structured Call-To-Action buttons (e.g., 'Dodaj zawodnika') guides users directly to the next logical step.
**Action:** Scan for isEmpty list conditionals and replace plain generic text fallbacks with structured layouts featuring explicit ElevatedButton.icon CTAs.
