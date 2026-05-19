import re

with open('VolleyballApp/frontend/lib/widgets/focus_player_widget.dart', 'r') as f:
    text = f.read()

text = text.replace(
'''    return GestureDetector(
      onDoubleTap: widget.onResetFocus,
      child: AspectRatio(
        aspectRatio: bw / bh,''',
'''    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onDoubleTap: widget.onResetFocus,
        child: AspectRatio(
          aspectRatio: bw / bh,'''
)

text = text.replace(
'''                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}''',
'''                  ],
                );
              },
            ),
          ),
        ),
      ),
      ),
    );
  }
}'''
)

with open('VolleyballApp/frontend/lib/widgets/focus_player_widget.dart', 'w') as f:
    f.write(text)
