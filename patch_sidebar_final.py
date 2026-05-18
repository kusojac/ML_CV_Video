import re
with open('VolleyballApp/frontend/lib/widgets/action_sidebar.dart', 'r') as f:
    text = f.read()

# Add closing bracket for DEL action MouseRegion
del_close_old = "                                        child: const Row(\n                                          children: [\n                                            Text('DEL', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),\n                                            SizedBox(width: 4),\n                                            Icon(Icons.delete, color: Colors.redAccent, size: 14),\n                                          ],\n                                        ),\n                                      ),\n                                    ),\n                                  ],\n                                ),\n                              ),"
del_close_new = "                                        child: const Row(\n                                          children: [\n                                            Text('DEL', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),\n                                            SizedBox(width: 4),\n                                            Icon(Icons.delete, color: Colors.redAccent, size: 14),\n                                          ],\n                                        ),\n                                      ),\n                                    ),\n                                    ),\n                                  ],\n                                ),\n                              ),"
text = text.replace(del_close_old, del_close_new, 1)

with open('VolleyballApp/frontend/lib/widgets/action_sidebar.dart', 'w') as f:
    f.write(text)
