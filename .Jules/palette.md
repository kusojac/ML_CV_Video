## 2024-05-20 - Empty State Improvements
**Learning:** Replacing plain text empty states with visually distinct layouts containing actionable icons and buttons significantly reduces friction for first-time users. In this app, many empty lists (like projects or artifacts) default to plain Text widgets.
**Action:** Always scan for `isEmpty` conditionals in lists or grids and replace generic `Text` fallbacks with structured empty states featuring a clear Call-To-Action.

## 2026-05-24 - Empty State CTAs
**Learning:** Relying solely on textual instructions or AppBar icons in empty states creates unnecessary friction, as users must scan for actions elsewhere. Providing immediate, contextual Call-To-Action buttons directly inside the empty state significantly improves discoverability and usability.
**Action:** When creating or updating empty list/grid views (`isEmpty` blocks), always include explicitly visible `ElevatedButton` (or similar) Call-To-Action elements within the empty state layout to guide the user's next steps.
## 2024-05-20 - Missing Tooltips on IconButtons
**Learning:** Icon-only interactive elements (`IconButton`) lacking `tooltip` or `semanticLabel` properties are inaccessible to screen readers and offer poor UX without hover text.
**Action:** Always verify `IconButton` implementations include a localized `tooltip` attribute to provide context and ensure accessibility compliance.
## 2024-05-24 - Missing Clear Filters CTA in Empty States
**Learning:** When users apply restrictive filters resulting in an empty list, providing only text instructions like 'Zmień filtry' (Change filters) forces them to manually hunt for filter controls. Adding an explicit 'Clear filters' button directly within the empty state significantly improves usability and error recovery.
**Action:** When creating empty states for filtered lists (e.g., `filteredActions.isEmpty`), always include a one-click Call-To-Action button (like `ElevatedButton.icon`) to instantly reset filters.
