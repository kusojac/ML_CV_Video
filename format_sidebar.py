with open('VolleyballApp/frontend/lib/widgets/action_sidebar.dart', 'r') as f:
    text = f.read()

# 1. Main outer InkWell
outer_old = "                    child: InkWell(\n                      onTap: () => widget.onActionSelected(action),\n                      borderRadius: BorderRadius.circular(8),\n                      child: Padding(\n                        padding: const EdgeInsets.all(12),"
outer_new = "                    child: MouseRegion(\n                      cursor: SystemMouseCursors.click,\n                      child: InkWell(\n                        onTap: () => widget.onActionSelected(action),\n                        borderRadius: BorderRadius.circular(8),\n                        child: Padding(\n                          padding: const EdgeInsets.all(12),"
text = text.replace(outer_old, outer_new, 1)

# 2. Main outer block closing
outer_close_old = "                            ],\n                          ),\n                        ],\n                      ),\n                    ),\n                  ),\n                ),\n                );"
outer_close_new = "                            ],\n                          ),\n                        ],\n                      ),\n                      ),\n                    ),\n                  ),\n                );\n              }).toList(),"
text = text.replace(outer_close_old, outer_close_new, 1)
# 3. EDIT InkWell
edit_old = "                                    InkWell(\n                                      onTap: () => _editAction(context, action),\n                                      child: const Row(\n                                        children: [\n                                          Text('EDIT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),\n                                          SizedBox(width: 4),\n                                          Icon(Icons.edit, color: Colors.white30, size: 14),\n                                        ],\n                                      ),\n                                    ),"
edit_new = "                                    MouseRegion(\n                                      cursor: SystemMouseCursors.click,\n                                      child: InkWell(\n                                        onTap: () => _editAction(context, action),\n                                        child: const Row(\n                                          children: [\n                                            Text('EDIT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),\n                                            SizedBox(width: 4),\n                                            Icon(Icons.edit, color: Colors.white30, size: 14),\n                                          ],\n                                        ),\n                                      ),\n                                    ),"
text = text.replace(edit_old, edit_new, 1)

# 4. DEL InkWell top
del_old = "                                    InkWell(\n                                      onTap: () async {\n                                        final bool? confirm = await showDialog<bool>("
del_new = "                                    MouseRegion(\n                                      cursor: SystemMouseCursors.click,\n                                      child: InkWell(\n                                        onTap: () async {\n                                        final bool? confirm = await showDialog<bool>("
text = text.replace(del_old, del_new, 1)

with open('VolleyballApp/frontend/lib/widgets/action_sidebar.dart', 'w') as f:
    f.write(text)
