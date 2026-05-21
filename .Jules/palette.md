## 2026-05-21 - Missing tooltips on icon-only buttons
**Learning:** Found several icon-only `IconButton` widgets in Flutter (e.g. in `ActionSidebar`) lacking `tooltip` attributes. Without a tooltip or semantic label, screen readers cannot provide context for these buttons, making the interface inaccessible.
**Action:** Always provide a `tooltip` (or `semanticLabel`) property for icon-only interactive elements in Flutter.
