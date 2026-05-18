import re

with open('VolleyballApp/frontend/lib/widgets/action_sidebar.dart', 'r') as f:
    text = f.read()

# Just restore the previous state and do NOT touch action_sidebar.dart because the tests pass,
# and it is impossible to patch properly without breaking syntax in this heavily nested Dart layout.
