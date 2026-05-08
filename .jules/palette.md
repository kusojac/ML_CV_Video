## 2025-01-16 - Add Tooltips to Icon-Only Buttons
**Learning:** Icon-only buttons without tooltips or ARIA labels provide no context to screen readers, making the app less accessible. Adding a simple `tooltip` string properly describes the purpose of actions like "Delete" or "Remove".
**Action:** Always include a `tooltip` or `semanticLabel` for interactive elements containing only icons.
