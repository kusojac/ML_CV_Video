## 2024-05-20 - Empty State Improvements
**Learning:** Replacing plain text empty states with visually distinct layouts containing actionable icons and buttons significantly reduces friction for first-time users. In this app, many empty lists (like projects or artifacts) default to plain Text widgets.
**Action:** Always scan for `isEmpty` conditionals in lists or grids and replace generic `Text` fallbacks with structured empty states featuring a clear Call-To-Action.

## 2026-05-24 - Empty State CTAs
**Learning:** Relying solely on textual instructions or AppBar icons in empty states creates unnecessary friction, as users must scan for actions elsewhere. Providing immediate, contextual Call-To-Action buttons directly inside the empty state significantly improves discoverability and usability.
**Action:** When creating or updating empty list/grid views (`isEmpty` blocks), always include explicitly visible `ElevatedButton` (or similar) Call-To-Action elements within the empty state layout to guide the user's next steps.
## 2024-05-20 - Missing Tooltips on IconButtons
**Learning:** Icon-only interactive elements (`IconButton`) lacking `tooltip` or `semanticLabel` properties are inaccessible to screen readers and offer poor UX without hover text.
**Action:** Always verify `IconButton` implementations include a localized `tooltip` attribute to provide context and ensure accessibility compliance.

## 2025-02-24 - Add explicit CTA button for empty player list
**Learning:** Empty states with plain text ("No players") rely on users finding contextual buttons elsewhere on the screen. Providing an explicit Call-To-Action (CTA) directly within the empty state drastically reduces friction and makes the interface more intuitive for users resolving the empty state.
**Action:** When designing or refactoring empty list/grid states, always integrate an explicit CTA button relevant to the user's workflow rather than relying on generic fallback text.
