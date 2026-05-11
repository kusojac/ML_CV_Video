## 2025-01-16 - Add Tooltips to Icon-Only Buttons
**Learning:** Icon-only buttons without tooltips or ARIA labels provide no context to screen readers, making the app less accessible. Adding a simple `tooltip` string properly describes the purpose of actions like "Delete" or "Remove".
**Action:** Always include a `tooltip` or `semanticLabel` for interactive elements containing only icons.
## 2024-05-18 - Tooltips on Flutter IconButtons
**Learning:** `IconButton`s in Flutter must always contain a `tooltip` or `semanticLabel` property, as otherwise screen readers will not be able to inform users about the button's action. This is a common accessibility trap in mobile and desktop applications.
**Action:** When adding or reviewing `IconButton`s that lack accompanying text labels, actively add the `tooltip` property with a descriptive label of what the button does.

## 2024-05-11 - Visually Structured Empty States
**Learning:** Leaving blank spaces for empty lists (like an empty Column or ReorderableListView) looks like a bug and leaves users confused about the current state or next steps.
**Action:** Always provide a visually structured empty state using a clear Icon, a bold title explaining the state, and a subtle subtitle offering guidance or a call-to-action when lists or dynamic content areas are empty.
