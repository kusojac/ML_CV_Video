## 2025-01-16 - Add Tooltips to Icon-Only Buttons
**Learning:** Icon-only buttons without tooltips or ARIA labels provide no context to screen readers, making the app less accessible. Adding a simple `tooltip` string properly describes the purpose of actions like "Delete" or "Remove".
**Action:** Always include a `tooltip` or `semanticLabel` for interactive elements containing only icons.
## 2024-05-18 - Tooltips on Flutter IconButtons
**Learning:** `IconButton`s in Flutter must always contain a `tooltip` or `semanticLabel` property, as otherwise screen readers will not be able to inform users about the button's action. This is a common accessibility trap in mobile and desktop applications.
**Action:** When adding or reviewing `IconButton`s that lack accompanying text labels, actively add the `tooltip` property with a descriptive label of what the button does.

## 2024-05-11 - Visually Structured Empty States
**Learning:** Leaving blank spaces for empty lists (like an empty Column or ReorderableListView) looks like a bug and leaves users confused about the current state or next steps.
**Action:** Always provide a visually structured empty state using a clear Icon, a bold title explaining the state, and a subtle subtitle offering guidance or a call-to-action when lists or dynamic content areas are empty.

## 2026-05-12 - Missing tooltips on IconButtons
**Learning:** Icon-only interactive elements like `IconButton` require a `tooltip` property in Flutter to provide context for screen readers and show hover text, otherwise they are inaccessible and lack clear intent.
**Action:** Always provide a `tooltip` property for icon-only `IconButton` widgets to ensure accessibility and improve UX.
## 2024-05-13 - Enhance Empty States and Tooltips
**Learning:** Replaced plain text empty state in `home_screen.dart` with a structured empty state including an icon, title, and clear instructions. Added `tooltip` to the delete button in the project tile to ensure screen reader users understand the action. This aligns with our existing Palette guidelines.
**Action:** Consistently apply these UX and accessibility improvements across the app's components to ensure a cohesive and user-friendly experience.
## 2024-05-16 - Visually Structured Empty States\n**Learning:** Replacing plain text empty states with visually structured components (combining an Icon, title, and descriptive subtitle) significantly improves user guidance and aligns with modern design patterns, even in complex desktop UIs like Flutter.\n**Action:** Always prefer structured empty states with clear calls to action over simple text messages when a data grid or list is empty.

## 2024-05-18 - Missing Tooltips on Icon-Only Buttons
**Learning:** Icon-only buttons (like `IconButton` in Flutter) lack context for screen readers and general accessibility if not paired with a `tooltip` or `semanticLabel`. In `ArtifactEditScreen`, the "remove player" button lacked this.
**Action:** Always ensure any standalone `Icon` wrapper designed for interaction (like `IconButton` or `GestureDetector` around an `Icon`) explicitly sets the `tooltip` property.
## 2024-05-19 - Centralized Theme Usage
**Learning:** Hardcoding generic styles like clipBehavior, shadows, and borders in multiple components creates inconsistency and bloats code. Using centralized ThemeData (e.g. CardTheme, ChipTheme) ensures uniform aesthetics across the whole application while decreasing code duplication.
**Action:** When redesigning screens, check if properties common to many widgets can be lifted into the global MaterialApp theme.
