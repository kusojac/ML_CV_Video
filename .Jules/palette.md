## 2024-05-14 - Add Tooltips to ActionSidebar IconButtons
**Learning:** In Flutter, icon-only interactive elements like `IconButton` require an explicit `tooltip` (or `semanticLabel`) property. Without it, screen readers cannot deduce the action's purpose, which makes dense lists—such as sub-actions and focus points in `ActionSidebar`—inaccessible.
**Action:** Always provide descriptive `tooltip` attributes when using `IconButton` or other non-text interactive widgets, to ensure visual and screen reader accessibility are maintained simultaneously.
