with open("VolleyballApp/frontend/lib/widgets/action_sidebar.dart", "r") as f:
    text = f.read()

# 1. Wrapping the main row InkWell
old1 = """                    child: InkWell(
                      onTap: () => widget.onActionSelected(action),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: ["""
new1 = """                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: () => widget.onActionSelected(action),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: ["""
text = text.replace(old1, new1)

# Add closing bracket for the first one
old1_close = """                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),"""
new1_close = """                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),"""
text = text.replace(old1_close, new1_close)

# 2. Wrapping EDIT
old2 = """                                    InkWell(
                                      onTap: () => _editAction(context, action),
                                      child: const Row(
                                        children: [
                                          Text('EDIT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.edit, color: Colors.white30, size: 14),
                                        ],
                                      ),
                                    ),"""
new2 = """                                    MouseRegion(
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
text = text.replace(old2, new2)

# 3. Wrapping DEL
old3 = """                                    InkWell(
                                      onTap: () async {
                                        final bool? confirm = await showDialog<bool>("""
new3 = """                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: () async {
                                        final bool? confirm = await showDialog<bool>("""
text = text.replace(old3, new3)

# 3. Close DEL
old3_close = """                                        child: const Row(
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
                              ),
                            ],
                          ),"""
new3_close = """                                        child: const Row(
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
                              ),
                            ],
                          ),"""
text = text.replace(old3_close, new3_close)

with open("VolleyballApp/frontend/lib/widgets/action_sidebar.dart", "w") as f:
    f.write(text)
