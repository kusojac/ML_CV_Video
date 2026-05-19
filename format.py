import re

with open('VolleyballApp/frontend/lib/widgets/video_player_widget.dart', 'r') as f:
    text = f.read()

# Replace first tap region
text = text.replace(
'''                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),''',
'''                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),'''
)

text = text.replace(
'''                      child: Text(
                        type,
                        style: TextStyle(
                          color: isChosen ? col : Colors.white70,
                          fontWeight: isChosen
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),''',
'''                        child: Text(
                          type,
                          style: TextStyle(
                            color: isChosen ? col : Colors.white70,
                            fontWeight: isChosen
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),'''
)

text = text.replace(
'''    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Czyszczenie fokusu po kliknięciu
            widget.onActionUpdated?.call(ActionModel(
              id: widget.selectedAction!.id,
              type: widget.selectedAction!.type,
              startMs: widget.selectedAction!.startMs,
              endMs: widget.selectedAction!.endMs,
              playerBox: [0.0, 0.0, 0.0, 0.0],
              playerId: widget.selectedAction!.playerId,
              confidence: widget.selectedAction!.confidence,
            ));
          },''',
'''    return Stack(
      fit: StackFit.expand,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Czyszczenie fokusu po kliknięciu
              widget.onActionUpdated?.call(ActionModel(
                id: widget.selectedAction!.id,
                type: widget.selectedAction!.type,
                startMs: widget.selectedAction!.startMs,
                endMs: widget.selectedAction!.endMs,
                playerBox: [0.0, 0.0, 0.0, 0.0],
                playerId: widget.selectedAction!.playerId,
                confidence: widget.selectedAction!.confidence,
              ));
            },'''
)

text = text.replace(
'''          onPanEnd: (d) {
            if (_dragStart != null && _dragCurrent != null) {
              final x1 = _dragStart!.dx / size.width * videoW;
              final y1 = _dragStart!.dy / size.height * videoH;
              final x2 = _dragCurrent!.dx / size.width * videoW;
              final y2 = _dragCurrent!.dy / size.height * videoH;
              if ((x2 - x1).abs() > 10 && (y2 - y1).abs() > 10) {
                widget.onActionUpdated?.call(ActionModel(
                  id: widget.selectedAction!.id,
                  type: widget.selectedAction!.type,
                  startMs: widget.selectedAction!.startMs,
                  endMs: widget.selectedAction!.endMs,
                  playerBox: [
                    x1 < x2 ? x1 : x2,
                    y1 < y2 ? y1 : y2,
                    x1 > x2 ? x1 : x2,
                    y1 > y2 ? y1 : y2,
                  ],
                  playerId: widget.selectedAction!.playerId,
                  confidence: widget.selectedAction!.confidence,
                ));
              }
            }
            setState(() {
              _dragStart = null;
              _dragCurrent = null;
            });
          },
        ),''',
'''            onPanEnd: (d) {
              if (_dragStart != null && _dragCurrent != null) {
                final x1 = _dragStart!.dx / size.width * videoW;
                final y1 = _dragStart!.dy / size.height * videoH;
                final x2 = _dragCurrent!.dx / size.width * videoW;
                final y2 = _dragCurrent!.dy / size.height * videoH;
                if ((x2 - x1).abs() > 10 && (y2 - y1).abs() > 10) {
                  widget.onActionUpdated?.call(ActionModel(
                    id: widget.selectedAction!.id,
                    type: widget.selectedAction!.type,
                    startMs: widget.selectedAction!.startMs,
                    endMs: widget.selectedAction!.endMs,
                    playerBox: [
                      x1 < x2 ? x1 : x2,
                      y1 < y2 ? y1 : y2,
                      x1 > x2 ? x1 : x2,
                      y1 > y2 ? y1 : y2,
                    ],
                    playerId: widget.selectedAction!.playerId,
                    confidence: widget.selectedAction!.confidence,
                  ));
                }
              }
              setState(() {
                _dragStart = null;
                _dragCurrent = null;
              });
            },
          ),
        ),'''
)

with open('VolleyballApp/frontend/lib/widgets/video_player_widget.dart', 'w') as f:
    f.write(text)


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
'''                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}''',
'''                  ),
                ],
              );
            }),
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
