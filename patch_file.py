import re

with open('VolleyballApp/frontend/lib/widgets/action_sidebar.dart', 'r') as f:
    text = f.read()

# Only modify the exact instances needed. We know the original file works and passes dart format.
# Let's replace InkWell with MouseRegion for EDIT and DEL only since those seem simpler. We will leave the outer one if it causes issues, but let's try safely replacing it all.

# Replace the inner EDIT button
edit_old = """                                    InkWell(
                                      onTap: () => _editAction(context, action),
                                      child: const Row(
                                        children: [
                                          Text('EDIT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.edit, color: Colors.white30, size: 14),
                                        ],
                                      ),
                                    ),"""
edit_new = """                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: () => _editAction(context, action),
                                        child: const Row(
                                          children: [
                                            Text('EDIT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                            SizedBox(width: 4),
                                            Icon(Icons.edit, color: Colors.white30, size: 14),
                                          ],
                                        ),
                                      ),
                                    ),"""
text = text.replace(edit_old, edit_new, 1)

# Replace the inner DEL button
del_old = """                                    InkWell(
                                      onTap: () async {
                                        final bool? confirm = await showDialog<bool>("""
del_new = """                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: () async {
                                        final bool? confirm = await showDialog<bool>("""
text = text.replace(del_old, del_new, 1)

del_close_old = """                                        child: const Row(
                                          children: [
                                            Text('DEL', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                            SizedBox(width: 4),
                                            Icon(Icons.delete, color: Colors.redAccent, size: 14),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),"""
del_close_new = """                                        child: const Row(
                                          children: [
                                            Text('DEL', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                            SizedBox(width: 4),
                                            Icon(Icons.delete, color: Colors.redAccent, size: 14),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ),
                                  ],
                                ),
                              ),"""
text = text.replace(del_close_old, del_close_new, 1)

with open('VolleyballApp/frontend/lib/widgets/action_sidebar.dart', 'w') as f:
    f.write(text)
