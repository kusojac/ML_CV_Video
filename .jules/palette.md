## 2024-05-18 - Tooltips on Flutter IconButtons
**Learning:** `IconButton`s in Flutter must always contain a `tooltip` or `semanticLabel` property, as otherwise screen readers will not be able to inform users about the button's action. This is a common accessibility trap in mobile and desktop applications.
**Action:** When adding or reviewing `IconButton`s that lack accompanying text labels, actively add the `tooltip` property with a descriptive label of what the button does.
