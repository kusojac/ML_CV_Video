## 2024-05-20 - Empty State Improvements
**Learning:** Replacing plain text empty states with visually distinct layouts containing actionable icons and buttons significantly reduces friction for first-time users. In this app, many empty lists (like projects or artifacts) default to plain Text widgets.
**Action:** Always scan for `isEmpty` conditionals in lists or grids and replace generic `Text` fallbacks with structured empty states featuring a clear Call-To-Action.
## 2024-05-20 - Missing Tooltips on IconButtons
**Learning:** Icon-only interactive elements (`IconButton`) lacking `tooltip` or `semanticLabel` properties are inaccessible to screen readers and offer poor UX without hover text.
**Action:** Always verify `IconButton` implementations include a localized `tooltip` attribute to provide context and ensure accessibility compliance.
