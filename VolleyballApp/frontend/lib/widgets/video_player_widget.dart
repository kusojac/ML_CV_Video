import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/action_model.dart';

// ─── Kolory typów akcji ─────────────────────────────────────────────────────

Color _actionColor(String type) {
  switch (type.toUpperCase()) {
    case 'BUMP':
    case 'RECEIVE':
    case 'DIG':
      return Colors.blueAccent;
    case 'SET':
      return Colors.greenAccent;
    case 'ATTACK':
    case 'RIGHT SPIKE':
    case 'LEFT SPIKE':
    case 'MIDDLE SPIKE':
      return Colors.redAccent;
    case 'SERVE':
    case 'JUMP SERVE':
    case 'FLOAT SERVE':
      return Colors.orangeAccent;
    case 'BLOCK':
      return const Color(0xFFCC88FF);
    case 'FREEBALL':
      return Colors.tealAccent;
    default:
      return Colors.purpleAccent;
  }
}

// ─── Widget ─────────────────────────────────────────────────────────────────

class VideoPlayerWidget extends StatefulWidget {
  final File videoFile;
  final List<ActionModel> actions;
  final ActionModel? selectedAction;
  final bool isEditMode;
  final Function(Duration) onPositionChanged;
  final Function(VideoController) onControllerReady;
  final ValueChanged<ActionModel>? onActionUpdated;
  final ValueChanged<ActionModel>? onActionAdded;
  final ValueChanged<ActionModel?>? onActionSelected;
  final List<ActionModel>? playlistActions;
  final ValueChanged<ActionModel>? onActionPlaylistToggled;
  final ActionKeyPointModel? selectedKeyPoint;
  final ValueChanged<ActionKeyPointModel?>? onKeyPointSelected;
  final ValueChanged<ActionKeyPointModel>? onKeyPointUpdated;

  const VideoPlayerWidget({
    super.key,
    required this.videoFile,
    required this.actions,
    this.selectedAction,
    this.isEditMode = false,
    required this.onPositionChanged,
    required this.onControllerReady,
    this.onActionUpdated,
    this.onActionAdded,
    this.onActionSelected,
    this.playlistActions,
    this.onActionPlaylistToggled,
    this.selectedKeyPoint,
    this.onKeyPointSelected,
    this.onKeyPointUpdated,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitializing = true;
  bool _isPlaying = false;
  Duration _currentPos = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Rysowanie bounding-box na wideo (edit mode)
  Offset? _dragStart;
  Offset? _dragCurrent;

  /// ID najechanego kursorem bloku wydarzenia na timeline
  String? _hoveredActionId;

  // Zaznaczanie zakresu na timeline
  double? _rangeStartMs; // punkt startowy zaznaczenia (ms)
  double? _rangeEndMs; // punkt końcowy zaznaczenia (ms)
  bool _isDraggingRange = false;

  // Poziom przybliżenia (zoom) osi czasu
  double _zoomLevel = 1.0;

  // Kontroler przewijania osi czasu
  final ScrollController _timelineScrollController = ScrollController();

  // Tryb przewijania kursorem po obszarze wideo
  bool _scrubMode = false;
  double? _scrubDragStartX;
  double? _scrubDragStartMs;

  // Prędkość odtwarzania
  double _playbackRate = 1.0;

  static const List<double> _kRates = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0];

  void _setRate(double rate) {
    _player.setRate(rate);
    setState(() => _playbackRate = rate);
  }

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  Future<void> _initPlayer() async {
    final path = widget.videoFile.path;
    await _player.open(Media('file:///$path'), play: false);

    _player.stream.position.listen((pos) {
      if (!mounted) return;
      if (_currentPos != pos) {
        _currentPos = pos;
        widget.onPositionChanged(pos);
      }
    });

    _player.stream.duration.listen((dur) {
      if (!mounted) return;
      setState(() => _totalDuration = dur);
    });

    _player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
    });

    if (!mounted) return;
    setState(() => _isInitializing = false);
    widget.onControllerReady(_controller);
  }

  @override
  void dispose() {
    _player.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAction?.id != oldWidget.selectedAction?.id &&
        widget.selectedAction != null) {
      if (_zoomLevel > 1.0) {
        _scrollToSelectedAction();
      }
    }
  }

  void _scrollToSelectedAction() {
    if (!mounted || !_timelineScrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_timelineScrollController.hasClients) return;

      final totalMs = _totalDuration.inMilliseconds.toDouble();
      if (totalMs <= 0) return;

      final maxScroll = _timelineScrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      final viewport = _timelineScrollController.position.viewportDimension;
      final timelineWidth = maxScroll + viewport;

      final startFrac = widget.selectedAction!.startMs / totalMs;
      final targetScroll = (startFrac * timelineWidth) - (viewport / 2);

      _timelineScrollController.animateTo(
        targetScroll.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _seekToMs(double ms) => _player.seek(Duration(milliseconds: ms.round()));

  // ─── Potwierdzenie nowej akcji ─────────────────────────────────────────────

  Future<void> _confirmNewAction(double startMs, double endMs) async {
    if (!mounted) return;
    // Normalizuj kolejność
    if (startMs > endMs) {
      final tmp = startMs;
      startMs = endMs;
      endMs = tmp;
    }
    if (endMs - startMs < 100) return; // zbyt krótkie zaznaczenie

    String selectedType = kVolleyballActions.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Colors.purpleAccent,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Nowa akcja',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zakres czasu
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Początek',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          _fmtMs(startMs),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white38,
                      size: 16,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Koniec',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          _fmtMs(endMs),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Typ akcji',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              // Przyciski wyboru typu
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kVolleyballActions.map((type) {
                  final isChosen = type == selectedType;
                  final col = _actionColor(type);
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isChosen
                              ? col.withAlpha(51)
                              : Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isChosen ? col : Colors.white24,
                            width: isChosen ? 2 : 1,
                          ),
                        ),
                        child: Text(
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
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Anuluj',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Dodaj'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final newAction = ActionModel(
        id: 'action_m_${DateTime.now().millisecondsSinceEpoch}',
        type: selectedType,
        startMs: startMs,
        endMs: endMs,
        playerBox: [0.0, 0.0, 0.0, 0.0],
        playerId: 'Unknown',
        confidence: 1.0,
      );
      widget.onActionAdded?.call(newAction);
    }
  }

  Future<void> _confirmNewSubAction(ActionModel parent, double startMs, double endMs) async {
    if (!mounted) return;
    if (startMs > endMs) {
      final tmp = startMs;
      startMs = endMs;
      endMs = tmp;
    }
    if (endMs - startMs < 100) return; // zbyt krótkie zaznaczenie

    startMs = startMs.clamp(parent.startMs, parent.endMs);
    endMs = endMs.clamp(startMs, parent.endMs);

    String selectedType = kVolleyballActions.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Colors.purpleAccent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Nowa pod-akcja (${parent.type})',
                style: const TextStyle(color: Colors.white, fontSize: 17),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Początek',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          _fmtMs(startMs),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white38,
                      size: 16,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Koniec',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          _fmtMs(endMs),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Typ pod-akcji',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kVolleyballActions.map((type) {
                  final isChosen = type == selectedType;
                  final col = _actionColor(type);
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isChosen
                              ? col.withAlpha(51)
                              : Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isChosen ? col : Colors.white24,
                            width: isChosen ? 2 : 1,
                          ),
                        ),
                        child: Text(
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
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Anuluj',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Dodaj'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final newSub = ActionModel(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        type: selectedType,
        startMs: startMs,
        endMs: endMs,
        playerBox: [0.0, 0.0, 0.0, 0.0],
        playerId: 'Unknown',
        confidence: 1.0,
      );
      final updatedParent = parent.copyWith(
        subActions: List<ActionModel>.from(parent.subActions)..add(newSub),
      );
      widget.onActionUpdated?.call(updatedParent);
      widget.onActionSelected?.call(newSub);
    }
  }

  ActionModel _updateActiveFocusBox(ActionModel action, List<double> newBox) {
    final updatedFocuses = action.playerFocuses.map((f) {
      if (f.id == action.activeFocusId) {
        return f.copyWith(playerBox: newBox);
      }
      return f;
    }).toList();
    return action.copyWith(
      playerFocuses: updatedFocuses,
      playerBox: newBox,
    );
  }

  String _fmtMs(double ms) {
    final d = Duration(milliseconds: ms.round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final mil = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return h > 0 ? '$h:$m:$s.$mil' : '$m:$s.$mil';
  }

  Widget _buildTimelineMarkers(double timelineWidth) {
    final totalMs = _totalDuration.inMilliseconds.toDouble();
    if (totalMs == 0) return const SizedBox.shrink();

    // Find active parent
    ActionModel? activeParent;
    if (widget.selectedAction != null) {
      final idx = widget.actions.indexWhere((a) => a.id == widget.selectedAction!.id);
      if (idx != -1) {
        activeParent = widget.actions[idx];
      } else {
        for (final a in widget.actions) {
          if (a.subActions.any((s) => s.id == widget.selectedAction!.id)) {
            activeParent = a;
            break;
          }
        }
      }
    }

    final double timelineMinMs = activeParent != null ? activeParent.startMs : 0.0;
    final double timelineMaxMs = activeParent != null ? activeParent.endMs : totalMs;
    final double timelineDurationMs = timelineMaxMs - timelineMinMs;

    final markers = <Widget>[];

    if (activeParent != null) {
      final parent = activeParent;
      // ──── Zoomed mode: Draw only activeParent and its subActions ────
      final hasSubs = parent.subActions.isNotEmpty;
      final color = _actionColor(parent.type);
      final isSelected = widget.selectedAction?.id == parent.id;
      final isInPlaylist = widget.playlistActions?.any((a) => a.id == parent.id) ?? false;

      // Draw the parent action occupying the top half
      markers.add(
        Positioned(
          left: 0,
          top: 0,
          bottom: hasSubs ? 18 : 0,
          width: timelineWidth,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredActionId = parent.id),
            onExit: (_) {
              if (_hoveredActionId == parent.id) {
                setState(() => _hoveredActionId = null);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _seekToMs(parent.startMs);
                widget.onActionSelected?.call(parent);
              },
              onDoubleTap: () {
                widget.onActionPlaylistToggled?.call(parent);
              },
              onHorizontalDragUpdate: null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withAlpha(
                        widget.isEditMode || _hoveredActionId == parent.id
                            ? 204
                            : 153,
                      ),
                      borderRadius: BorderRadius.circular(widget.isEditMode ? 6 : 3),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : isInPlaylist
                          ? Border.all(color: Colors.white, width: 1.5)
                          : (_hoveredActionId == parent.id
                                ? Border.all(color: Colors.white70, width: 2)
                                : (widget.isEditMode
                                      ? Border.all(color: Colors.white54, width: 1)
                                      : null)),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${parent.type} (Nadrzędna)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Draw sub-actions in the bottom half
      for (final sub in parent.subActions) {
        final subStartFrac = ((sub.startMs - timelineMinMs) / timelineDurationMs).clamp(0.0, 1.0);
        final subEndFrac = ((sub.endMs - timelineMinMs) / timelineDurationMs).clamp(0.0, 1.0);
        final subW = ((subEndFrac - subStartFrac) * timelineWidth).clamp(2.0, timelineWidth);
        final subColor = _actionColor(sub.type);
        final isSubSelected = widget.selectedAction?.id == sub.id;

        markers.add(
          Positioned(
            left: subStartFrac * timelineWidth,
            top: 18,
            bottom: 0,
            width: subW,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredActionId = sub.id),
              onExit: (_) {
                if (_hoveredActionId == sub.id) {
                  setState(() => _hoveredActionId = null);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: widget.isEditMode
                    ? (details) {
                        final msDelta = (details.primaryDelta ?? 0) / timelineWidth * timelineDurationMs;
                        final subDuration = sub.endMs - sub.startMs;
                        final newStart = (sub.startMs + msDelta).clamp(parent.startMs, parent.endMs - subDuration);
                        final newEnd = newStart + subDuration;

                        final updatedSub = sub.copyWith(
                          startMs: newStart,
                          endMs: newEnd,
                        );

                        final List<ActionModel> newSubs = parent.subActions.map((s) {
                          return s.id == sub.id ? updatedSub : s;
                        }).toList();

                        _seekToMs(newStart);

                        widget.onActionUpdated?.call(
                          parent.copyWith(
                            subActions: newSubs,
                          ),
                        );
                      }
                    : null,
                onTap: () {
                  _seekToMs(sub.startMs);
                  widget.onActionSelected?.call(sub);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: subColor.withAlpha(
                          widget.isEditMode || _hoveredActionId == sub.id ? 204 : 153,
                        ),
                        borderRadius: BorderRadius.circular(widget.isEditMode ? 4 : 2),
                        border: isSubSelected
                            ? Border.all(color: Colors.white, width: 1.5)
                            : (_hoveredActionId == sub.id
                                  ? Border.all(color: Colors.white70, width: 1.5)
                                  : (widget.isEditMode
                                        ? Border.all(color: Colors.white54, width: 0.5)
                                        : null)),
                      ),
                    ),
                    if (subW > 24)
                      Center(
                        child: Text(
                          sub.type.substring(0, sub.type.length.clamp(0, 3)),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black.withAlpha(180), blurRadius: 1.5),
                            ],
                          ),
                        ),
                      ),
                    // Left resize handle
                    if (widget.isEditMode)
                      Positioned(
                        left: -4,
                        top: 0,
                        bottom: 0,
                        width: 12,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (details) {
                              final msDelta = (details.primaryDelta ?? 0) / timelineWidth * timelineDurationMs;
                              final newStart = (sub.startMs + msDelta).clamp(parent.startMs, sub.endMs - 100);

                              final updatedSub = sub.copyWith(
                                startMs: newStart,
                              );

                              final List<ActionModel> newSubs = parent.subActions.map((s) {
                                return s.id == sub.id ? updatedSub : s;
                              }).toList();

                              _seekToMs(newStart);

                              widget.onActionUpdated?.call(
                                parent.copyWith(
                                  subActions: newSubs,
                                ),
                              );
                            },
                            child: Center(
                              child: Container(
                                height: double.infinity,
                                width: 4,
                                decoration: BoxDecoration(
                                  color: isSubSelected ? Colors.white : Colors.white70,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 1, spreadRadius: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Right resize handle
                    if (widget.isEditMode)
                      Positioned(
                        right: -4,
                        top: 0,
                        bottom: 0,
                        width: 12,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (details) {
                              final msDelta = (details.primaryDelta ?? 0) / timelineWidth * timelineDurationMs;
                              final newEnd = (sub.endMs + msDelta).clamp(sub.startMs + 100, parent.endMs);

                              final updatedSub = sub.copyWith(
                                endMs: newEnd,
                              );

                              final List<ActionModel> newSubs = parent.subActions.map((s) {
                                return s.id == sub.id ? updatedSub : s;
                              }).toList();

                              _seekToMs(newEnd);

                              widget.onActionUpdated?.call(
                                parent.copyWith(
                                  subActions: newSubs,
                                ),
                              );
                            },
                            child: Center(
                              child: Container(
                                height: double.infinity,
                                width: 4,
                                decoration: BoxDecoration(
                                  color: isSubSelected ? Colors.white : Colors.white70,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 1, spreadRadius: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Render parent key points
      for (final kp in parent.keyPoints) {
        final kpFrac = ((kp.timeMs - timelineMinMs) / timelineDurationMs).clamp(0.0, 1.0);
        final isSelected = widget.selectedKeyPoint?.id == kp.id;
        markers.add(
          Positioned(
            left: kpFrac * timelineWidth - 8,
            top: 2,
            width: 16,
            height: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _seekToMs(kp.timeMs);
                widget.onKeyPointSelected?.call(kp);
              },
              onHorizontalDragUpdate: widget.isEditMode
                  ? (details) {
                      final msDelta = (details.primaryDelta ?? 0) / timelineWidth * timelineDurationMs;
                      final newTime = (kp.timeMs + msDelta).clamp(parent.startMs, parent.endMs);
                      _seekToMs(newTime);
                      widget.onKeyPointUpdated?.call(kp.copyWith(timeMs: newTime));
                    }
                  : null,
              child: Icon(
                Icons.diamond,
                color: Colors.amber,
                size: isSelected ? 16 : 12,
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
              ),
            ),
          ),
        );
      }

      // Render sub-action key points
      for (final sub in parent.subActions) {
        for (final kp in sub.keyPoints) {
          final kpFrac = ((kp.timeMs - timelineMinMs) / timelineDurationMs).clamp(0.0, 1.0);
          final isSelected = widget.selectedKeyPoint?.id == kp.id;
          markers.add(
            Positioned(
              left: kpFrac * timelineWidth - 8,
              top: 20,
              width: 16,
              height: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _seekToMs(kp.timeMs);
                  widget.onKeyPointSelected?.call(kp);
                },
                onHorizontalDragUpdate: widget.isEditMode
                    ? (details) {
                        final msDelta = (details.primaryDelta ?? 0) / timelineWidth * timelineDurationMs;
                        final newTime = (kp.timeMs + msDelta).clamp(sub.startMs, sub.endMs);
                        _seekToMs(newTime);
                        widget.onKeyPointUpdated?.call(kp.copyWith(timeMs: newTime));
                      }
                    : null,
                child: Icon(
                  Icons.diamond_outlined,
                  color: Colors.amberAccent,
                  size: isSelected ? 16 : 12,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
          );
        }
      }
    } else {
      // ──── Zoomed out mode: Draw all actions normally ────
      for (final action in widget.actions) {
        final hasSubs = action.subActions.isNotEmpty;
        final startFrac = (action.startMs / totalMs).clamp(0.0, 1.0);
        final endFrac = (action.endMs / totalMs).clamp(0.0, 1.0);
        final w = ((endFrac - startFrac) * timelineWidth).clamp(2.0, timelineWidth);
        final color = _actionColor(action.type);
        final isSelected = widget.selectedAction?.id == action.id;
        final isInPlaylist = widget.playlistActions?.any((a) => a.id == action.id) ?? false;

        markers.add(
          Positioned(
            left: startFrac * timelineWidth,
            top: 0,
            bottom: hasSubs ? 18 : 0,
            width: w,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredActionId = action.id),
              onExit: (_) {
                if (_hoveredActionId == action.id) {
                  setState(() => _hoveredActionId = null);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (widget.isEditMode && !hasSubs)
                    ? (details) {
                        final msDelta = (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                        final newStart = (action.startMs + msDelta).clamp(0.0, totalMs);
                        final newEnd = (action.endMs + msDelta).clamp(newStart, totalMs);

                        _seekToMs(newStart);

                        widget.onActionUpdated?.call(
                          action.copyWith(
                            startMs: newStart,
                            endMs: newEnd,
                          ),
                        );
                      }
                    : null,
                onTap: () {
                  _seekToMs(action.startMs);
                  widget.onActionSelected?.call(action);
                },
                onDoubleTap: () {
                  widget.onActionPlaylistToggled?.call(action);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: color.withAlpha(
                          widget.isEditMode || _hoveredActionId == action.id
                              ? 204
                              : 153,
                        ),
                        borderRadius: BorderRadius.circular(widget.isEditMode ? 6 : 3),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : isInPlaylist
                            ? Border.all(color: Colors.white, width: 1.5)
                            : (_hoveredActionId == action.id
                                  ? Border.all(color: Colors.white70, width: 2)
                                  : (widget.isEditMode
                                        ? Border.all(color: Colors.white54, width: 1)
                                        : null)),
                      ),
                    ),
                    if (w > 30)
                      Center(
                        child: Text(
                          action.type.substring(0, action.type.length.clamp(0, 3)),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black.withAlpha(180), blurRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    // Left handle
                    if (widget.isEditMode && !hasSubs)
                      Positioned(
                        left: -6,
                        top: 0,
                        bottom: 0,
                        width: 16,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (details) {
                              final msDelta = (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                              final newStart = (action.startMs + msDelta).clamp(0.0, action.endMs - 100);

                              _seekToMs(newStart);

                              widget.onActionUpdated?.call(
                                action.copyWith(
                                  startMs: newStart,
                                ),
                              );
                            },
                            child: Center(
                              child: Container(
                                height: double.infinity,
                                width: 4,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 1, spreadRadius: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Right handle
                    if (widget.isEditMode && !hasSubs)
                      Positioned(
                        right: -6,
                        top: 0,
                        bottom: 0,
                        width: 16,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (details) {
                              final msDelta = (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                              final newEnd = (action.endMs + msDelta).clamp(action.startMs + 100, totalMs);

                              _seekToMs(newEnd);

                              widget.onActionUpdated?.call(
                                action.copyWith(
                                  endMs: newEnd,
                                ),
                              );
                            },
                            child: Center(
                              child: Container(
                                height: double.infinity,
                                width: 4,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 1, spreadRadius: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Render all key points in zoomed-out mode
      for (final action in widget.actions) {
        for (final kp in action.keyPoints) {
          final kpFrac = (kp.timeMs / totalMs).clamp(0.0, 1.0);
          final isSelected = widget.selectedKeyPoint?.id == kp.id;
          markers.add(
            Positioned(
              left: kpFrac * timelineWidth - 8,
              top: 10,
              width: 16,
              height: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _seekToMs(kp.timeMs);
                  widget.onKeyPointSelected?.call(kp);
                },
                onHorizontalDragUpdate: widget.isEditMode
                    ? (details) {
                        final msDelta = (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                        final newTime = (kp.timeMs + msDelta).clamp(action.startMs, action.endMs);
                        _seekToMs(newTime);
                        widget.onKeyPointUpdated?.call(kp.copyWith(timeMs: newTime));
                      }
                    : null,
                child: Icon(
                  Icons.diamond,
                  color: Colors.amber,
                  size: isSelected ? 16 : 12,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
          );
        }
        for (final sub in action.subActions) {
          for (final kp in sub.keyPoints) {
            final kpFrac = (kp.timeMs / totalMs).clamp(0.0, 1.0);
            final isSelected = widget.selectedKeyPoint?.id == kp.id;
            markers.add(
              Positioned(
                left: kpFrac * timelineWidth - 8,
                top: 10,
                width: 16,
                height: 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _seekToMs(kp.timeMs);
                    widget.onKeyPointSelected?.call(kp);
                  },
                  onHorizontalDragUpdate: widget.isEditMode
                      ? (details) {
                          final msDelta = (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                          final newTime = (kp.timeMs + msDelta).clamp(sub.startMs, sub.endMs);
                          _seekToMs(newTime);
                          widget.onKeyPointUpdated?.call(kp.copyWith(timeMs: newTime));
                        }
                      : null,
                  child: Icon(
                    Icons.diamond_outlined,
                    color: Colors.amberAccent,
                    size: isSelected ? 16 : 12,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
              ),
            );
          }
        }
      }
    }

    // Preview of selected range (during drag)
    if (_isDraggingRange &&
        _rangeStartMs != null &&
        _rangeEndMs != null &&
        _totalDuration.inMilliseconds > 0) {
      final lo = _rangeStartMs!.clamp(timelineMinMs, timelineMaxMs);
      final hi = _rangeEndMs!.clamp(timelineMinMs, timelineMaxMs);
      final left = ((lo - timelineMinMs) / timelineDurationMs * timelineWidth).clamp(0.0, timelineWidth);
      final right = ((hi - timelineMinMs) / timelineDurationMs * timelineWidth).clamp(0.0, timelineWidth);
      final selLeft = left < right ? left : right;
      final selWidth = (left - right).abs().clamp(1.0, timelineWidth);

      markers.add(
        Positioned(
          left: selLeft,
          top: 0,
          bottom: 0,
          width: selWidth,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withAlpha(80),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.purpleAccent, width: 1.5),
            ),
          ),
        ),
      );

      markers.add(
        Positioned(
          left: selLeft,
          top: -4,
          bottom: -4,
          width: 2,
          child: Container(color: Colors.purpleAccent),
        ),
      );

      markers.add(
        Positioned(
          left: selLeft + selWidth - 2,
          top: -4,
          bottom: -4,
          width: 2,
          child: Container(color: Colors.purpleAccent),
        ),
      );
    }

    return Stack(children: markers);
  }

  // ─── Pasek postępu + timeline ─────────────────────────────────────────────

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _player.stream.position,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final total = _totalDuration;
        final totalMs = total.inMilliseconds.toDouble();

        // Find active parent
        ActionModel? activeParent;
        if (widget.selectedAction != null) {
          final idx = widget.actions.indexWhere((a) => a.id == widget.selectedAction!.id);
          if (idx != -1) {
            activeParent = widget.actions[idx];
          } else {
            for (final a in widget.actions) {
              if (a.subActions.any((s) => s.id == widget.selectedAction!.id)) {
                activeParent = a;
                break;
              }
            }
          }
        }

        final double timelineMinMs = activeParent != null ? activeParent.startMs : 0.0;
        final double timelineMaxMs = activeParent != null ? activeParent.endMs : totalMs;
        final double timelineDurationMs = timelineMaxMs - timelineMinMs;

        final progress = timelineDurationMs > 0
            ? (pos.inMilliseconds - timelineMinMs) / timelineDurationMs
            : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final timelineWidth = constraints.maxWidth * _zoomLevel;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Etykiety czasu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmtMs(pos.inMilliseconds.toDouble()),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (widget.isEditMode)
                      Row(
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: Colors.purpleAccent,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _rangeStartMs != null && _rangeEndMs != null
                                ? '${_fmtMs(_rangeStartMs!.clamp(timelineMinMs, timelineMaxMs))} → '
                                      '${_fmtMs(_rangeEndMs!.clamp(timelineMinMs, timelineMaxMs))}'
                                : (activeParent != null
                                    ? 'Przeciągnij w zakresie akcji nadrzędnej aby dodać pod-akcję'
                                    : 'Przeciągnij aby dodać akcję'),
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        if (activeParent != null) ...[
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.zoom_out_map,
                              color: Colors.purpleAccent,
                              size: 12,
                            ),
                            label: const Text(
                              'Pełna oś czasu',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              widget.onActionSelected?.call(null);
                            },
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (_zoomLevel > 1.0)
                          Text(
                            'Zoom: ${_zoomLevel.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        if (_zoomLevel > 1.0) const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.zoom_out,
                            color: Colors.white54,
                            size: 14,
                          ),
                          tooltip: 'Oddal / Zoom out',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(
                            () => _zoomLevel = (_zoomLevel - 0.5).clamp(
                              1.0,
                              10.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.zoom_in,
                            color: Colors.white54,
                            size: 14,
                          ),
                          tooltip: 'Przybliż / Zoom in',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(
                            () => _zoomLevel = (_zoomLevel + 0.5).clamp(
                              1.0,
                              10.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _fmtMs(totalMs),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Pasek timeline z gesture
                Scrollbar(
                  controller: _timelineScrollController,
                  thumbVisibility: true,
                  thickness: 8,
                  child: SingleChildScrollView(
                    controller: _timelineScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: _isDraggingRange
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // ── Ruch / przewijanie (bez edit mode) ───────────────────
                      onHorizontalDragUpdate: widget.isEditMode
                          ? null
                          : (details) {
                              final rel =
                                  (details.localPosition.dx / timelineWidth)
                                      .clamp(0.0, 1.0);
                              _seekToMs(timelineMinMs + rel * timelineDurationMs);
                            },
                      // ── Tap bez edit: seek ─────────────────────────────────
                      onTapUp: widget.isEditMode
                          ? null
                          : (details) {
                              final rel =
                                  (details.localPosition.dx / timelineWidth)
                                      .clamp(0.0, 1.0);
                              _seekToMs(timelineMinMs + rel * timelineDurationMs);
                            },
                      // ── Drag w edit: zaznaczenie zakresu ──────────────────
                      onPanStart: widget.isEditMode
                          ? (details) {
                              final rel =
                                  (details.localPosition.dx / timelineWidth)
                                      .clamp(0.0, 1.0);
                              final ms = timelineMinMs + rel * timelineDurationMs;
                              setState(() {
                                _rangeStartMs = ms;
                                _rangeEndMs = ms;
                                _isDraggingRange = true;
                              });
                              _seekToMs(ms);
                            }
                          : null,
                      onPanUpdate: widget.isEditMode
                          ? (details) {
                              final rel =
                                  (details.localPosition.dx / timelineWidth)
                                      .clamp(0.0, 1.0);
                              final ms = timelineMinMs + rel * timelineDurationMs;
                              setState(() => _rangeEndMs = ms);
                              _seekToMs(ms);
                            }
                          : null,
                      onPanEnd: widget.isEditMode
                          ? (_) async {
                              final start = _rangeStartMs;
                              final end = _rangeEndMs;
                              setState(() {
                                _isDraggingRange = false;
                                _rangeStartMs = null;
                                _rangeEndMs = null;
                              });
                              if (start != null && end != null) {
                                final clampedStart = start.clamp(timelineMinMs, timelineMaxMs);
                                final clampedEnd = end.clamp(timelineMinMs, timelineMaxMs);
                                if (activeParent != null) {
                                  await _confirmNewSubAction(activeParent, clampedStart, clampedEnd);
                                } else {
                                  await _confirmNewAction(clampedStart, clampedEnd);
                                }
                              }
                            }
                          : null,
                      child: SizedBox(
                        height: 36,
                        width: timelineWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Tło (track)
                            Positioned.fill(
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            // Odtworzona część
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: (timelineWidth * progress.clamp(0.0, 1.0))
                                  .clamp(0.0, timelineWidth),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurpleAccent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            // Markery akcji
                            Positioned.fill(
                              child: _buildTimelineMarkers(timelineWidth),
                            ),
                            // Głowica (playhead) — linia pionowa
                            Positioned(
                              left: (timelineWidth * progress.clamp(0.0, 1.0))
                                  .clamp(0.0, timelineWidth - 2),
                              top: -4,
                              bottom: -4,
                              width: 2,
                              child: Container(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Bounding box na wideo ────────────────────────────────────────────────

  Widget _buildVideoBoundingBoxOverlay(
    Size size,
    double videoW,
    double videoH,
  ) {
    if (!widget.isEditMode) {
      return const SizedBox.shrink();
    }
    if (widget.selectedKeyPoint == null && widget.selectedAction == null) {
      return const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.selectedKeyPoint != null) {
              widget.onKeyPointUpdated?.call(
                widget.selectedKeyPoint!.copyWith(playerBox: [0.0, 0.0, 0.0, 0.0]),
              );
            } else if (widget.selectedAction != null) {
              // Czyszczenie fokusu po kliknięciu
              widget.onActionUpdated?.call(
                _updateActiveFocusBox(widget.selectedAction!, [0.0, 0.0, 0.0, 0.0]),
              );
            }
          },
          onPanStart: (d) => setState(() {
            _dragStart = d.localPosition;
            _dragCurrent = d.localPosition;
          }),
          onPanUpdate: (d) => setState(() => _dragCurrent = d.localPosition),
          onPanEnd: (d) {
            if (_dragStart != null && _dragCurrent != null) {
              final x1 = _dragStart!.dx / size.width * videoW;
              final y1 = _dragStart!.dy / size.height * videoH;
              final x2 = _dragCurrent!.dx / size.width * videoW;
              final y2 = _dragCurrent!.dy / size.height * videoH;
              if ((x2 - x1).abs() > 10 && (y2 - y1).abs() > 10) {
                final newBox = [
                  x1 < x2 ? x1 : x2,
                  y1 < y2 ? y1 : y2,
                  x1 > x2 ? x1 : x2,
                  y1 > y2 ? y1 : y2,
                ];
                if (widget.selectedKeyPoint != null) {
                  widget.onKeyPointUpdated?.call(
                    widget.selectedKeyPoint!.copyWith(playerBox: newBox),
                  );
                } else if (widget.selectedAction != null) {
                  widget.onActionUpdated?.call(
                    _updateActiveFocusBox(
                      widget.selectedAction!,
                      newBox,
                    ),
                  );
                }
              }
            }
            setState(() {
              _dragStart = null;
              _dragCurrent = null;
            });
          },
        ),
        if (_dragStart != null && _dragCurrent != null)
          Positioned(
            left: _dragStart!.dx < _dragCurrent!.dx
                ? _dragStart!.dx
                : _dragCurrent!.dx,
            top: _dragStart!.dy < _dragCurrent!.dy
                ? _dragStart!.dy
                : _dragCurrent!.dy,
            width: (_dragCurrent!.dx - _dragStart!.dx).abs(),
            height: (_dragCurrent!.dy - _dragStart!.dy).abs(),
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.selectedKeyPoint != null ? Colors.amber : Colors.redAccent,
                    width: 2,
                  ),
                  color: (widget.selectedKeyPoint != null ? Colors.amber : Colors.redAccent).withAlpha(51),
                ),
              ),
            ),
          )
        else if (widget.selectedKeyPoint != null) ...[
          () {
            final box = widget.selectedKeyPoint!.playerBox;
            if (box.length != 4 || box.every((v) => v == 0.0)) {
              return const SizedBox.shrink();
            }

            final left = box[0] / videoW * size.width;
            final top = box[1] / videoH * size.height;
            final width = ((box[2] - box[0]) / videoW * size.width).abs();
            final height = ((box[3] - box[1]) / videoH * size.height).abs();

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.amber,
                        width: 2,
                      ),
                      color: Colors.amber.withAlpha(51),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: Colors.black54,
                        child: Text(
                          widget.selectedKeyPoint!.description.isNotEmpty
                              ? widget.selectedKeyPoint!.description
                              : "Kluczowy punkt",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Lewy górny róg
                  Positioned(
                    left: -8,
                    top: -8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpLeftDownRight,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          final dx = d.delta.dx / size.width * videoW;
                          final dy = d.delta.dy / size.height * videoH;
                          final b = widget.selectedKeyPoint!.playerBox;
                          final newBox = [
                            (b[0] + dx).clamp(0.0, b[2] - 10.0),
                            (b[1] + dy).clamp(0.0, b[3] - 10.0),
                            b[2],
                            b[3],
                          ];
                          widget.onKeyPointUpdated?.call(
                            widget.selectedKeyPoint!.copyWith(playerBox: newBox),
                          );
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            border: Border.all(color: Colors.black),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Prawy górny róg
                  Positioned(
                    right: -8,
                    top: -8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpRightDownLeft,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          final dx = d.delta.dx / size.width * videoW;
                          final dy = d.delta.dy / size.height * videoH;
                          final b = widget.selectedKeyPoint!.playerBox;
                          final newBox = [
                            b[0],
                            (b[1] + dy).clamp(0.0, b[3] - 10.0),
                            (b[2] + dx).clamp(b[0] + 10.0, videoW),
                            b[3],
                          ];
                          widget.onKeyPointUpdated?.call(
                            widget.selectedKeyPoint!.copyWith(playerBox: newBox),
                          );
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            border: Border.all(color: Colors.black),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Lewy dolny róg
                  Positioned(
                    left: -8,
                    bottom: -8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpRightDownLeft,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          final dx = d.delta.dx / size.width * videoW;
                          final dy = d.delta.dy / size.height * videoH;
                          final b = widget.selectedKeyPoint!.playerBox;
                          final newBox = [
                            (b[0] + dx).clamp(0.0, b[2] - 10.0),
                            b[1],
                            b[2],
                            (b[3] + dy).clamp(b[1] + 10.0, videoH),
                          ];
                          widget.onKeyPointUpdated?.call(
                            widget.selectedKeyPoint!.copyWith(playerBox: newBox),
                          );
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            border: Border.all(color: Colors.black),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Prawy dolny róg
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpLeftDownRight,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          final dx = d.delta.dx / size.width * videoW;
                          final dy = d.delta.dy / size.height * videoH;
                          final b = widget.selectedKeyPoint!.playerBox;
                          final newBox = [
                            b[0],
                            b[1],
                            (b[2] + dx).clamp(b[0] + 10.0, videoW),
                            (b[3] + dy).clamp(b[1] + 10.0, videoH),
                          ];
                          widget.onKeyPointUpdated?.call(
                            widget.selectedKeyPoint!.copyWith(playerBox: newBox),
                          );
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            border: Border.all(color: Colors.black),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }()
        ]
        else if (widget.selectedAction != null)
          ...widget.selectedAction!.playerFocuses.map((focus) {
            final isActive = focus.id == widget.selectedAction!.activeFocusId;
            final box = focus.playerBox;
            if (box.length != 4 || box.every((v) => v == 0.0)) {
              return const SizedBox.shrink();
            }

            final left = box[0] / videoW * size.width;
            final top = box[1] / videoH * size.height;
            final width = ((box[2] - box[0]) / videoW * size.width).abs();
            final height = ((box[3] - box[1]) / videoH * size.height).abs();

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive ? Colors.greenAccent : Colors.white24,
                        width: isActive ? 2 : 1.5,
                      ),
                      color: isActive
                          ? Colors.greenAccent.withAlpha(51)
                          : Colors.white.withAlpha(15),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: Colors.black54,
                        child: Text(
                          focus.name,
                          style: TextStyle(
                            color: isActive ? Colors.greenAccent : Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isActive) ...[
                    // Lewy górny róg
                    Positioned(
                      left: -8,
                      top: -8,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpLeftDownRight,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            final dx = d.delta.dx / size.width * videoW;
                            final dy = d.delta.dy / size.height * videoH;
                            final b = focus.playerBox;
                            final newBox = [
                              (b[0] + dx).clamp(0.0, b[2] - 10.0),
                              (b[1] + dy).clamp(0.0, b[3] - 10.0),
                              b[2],
                              b[3],
                            ];
                            widget.onActionUpdated?.call(
                              _updateActiveFocusBox(widget.selectedAction!, newBox),
                            );
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              border: Border.all(color: Colors.black),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Prawy górny róg
                    Positioned(
                      right: -8,
                      top: -8,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpRightDownLeft,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            final dx = d.delta.dx / size.width * videoW;
                            final dy = d.delta.dy / size.height * videoH;
                            final b = focus.playerBox;
                            final newBox = [
                              b[0],
                              (b[1] + dy).clamp(0.0, b[3] - 10.0),
                              (b[2] + dx).clamp(b[0] + 10.0, videoW),
                              b[3],
                            ];
                            widget.onActionUpdated?.call(
                              _updateActiveFocusBox(widget.selectedAction!, newBox),
                            );
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              border: Border.all(color: Colors.black),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Lewy dolny róg
                    Positioned(
                      left: -8,
                      bottom: -8,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpRightDownLeft,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            final dx = d.delta.dx / size.width * videoW;
                            final dy = d.delta.dy / size.height * videoH;
                            final b = focus.playerBox;
                            final newBox = [
                              (b[0] + dx).clamp(0.0, b[2] - 10.0),
                              b[1],
                              b[2],
                              (b[3] + dy).clamp(b[1] + 10.0, videoH),
                            ];
                            widget.onActionUpdated?.call(
                              _updateActiveFocusBox(widget.selectedAction!, newBox),
                            );
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              border: Border.all(color: Colors.black),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Prawy dolny róg
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpLeftDownRight,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            final dx = d.delta.dx / size.width * videoW;
                            final dy = d.delta.dy / size.height * videoH;
                            final b = focus.playerBox;
                            final newBox = [
                              b[0],
                              b[1],
                              (b[2] + dx).clamp(b[0] + 10.0, videoW),
                              (b[3] + dy).clamp(b[1] + 10.0, videoH),
                            ];
                            widget.onActionUpdated?.call(
                              _updateActiveFocusBox(widget.selectedAction!, newBox),
                            );
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              border: Border.all(color: Colors.black),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── Kontrola prędkości ─────────────────────────────────────────────────────

  Widget _buildSpeedControl() {
    final isSlowMo = _playbackRate < 1.0;
    final isNormal = _playbackRate == 1.0;

    return PopupMenuButton<double>(
      tooltip: 'Prędkość odtwarzania',
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, -200),
      onSelected: _setRate,
      itemBuilder: (_) => _kRates.map((rate) {
        final isSelected = rate == _playbackRate;
        String label;
        if (rate == 1.0) {
          label = '${rate}x (normalna)';
        } else if (rate < 1.0) {
          label = '$rate× (zwolnione)';
        } else {
          label = '$rate× (przyspieszone)';
        }
        return PopupMenuItem<double>(
          value: rate,
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected
                    ? (rate < 1.0
                          ? Colors.cyanAccent
                          : rate > 1.0
                          ? Colors.orangeAccent
                          : Colors.greenAccent)
                    : Colors.white38,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isNormal
              ? Colors.white.withValues(alpha: 0.07)
              : isSlowMo
              ? Colors.cyanAccent.withValues(alpha: 0.15)
              : Colors.orangeAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNormal
                ? Colors.white24
                : isSlowMo
                ? Colors.cyanAccent
                : Colors.orangeAccent,
            width: isNormal ? 1.0 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSlowMo
                  ? Icons.slow_motion_video
                  : isNormal
                  ? Icons.speed
                  : Icons.fast_forward,
              size: 15,
              color: isNormal
                  ? Colors.white54
                  : isSlowMo
                  ? Colors.cyanAccent
                  : Colors.orangeAccent,
            ),
            const SizedBox(width: 5),
            Text(
              '$_playbackRate×',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isNormal ? FontWeight.normal : FontWeight.bold,
                color: isNormal
                    ? Colors.white54
                    : isSlowMo
                    ? Colors.cyanAccent
                    : Colors.orangeAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 12),
            Text('Ładowanie wideo...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Wideo ─────────────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final videoW =
                  _controller.player.state.width?.toDouble() ?? 1920.0;
              final videoH =
                  _controller.player.state.height?.toDouble() ?? 1080.0;

              return Center(
                child: AspectRatio(
                  aspectRatio: videoW / videoH,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final size = Size(box.maxWidth, box.maxHeight);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Video(controller: _controller),
                          _buildVideoBoundingBoxOverlay(size, videoW, videoH),
                          // Nakładka scrub mode
                          if (_scrubMode)
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (d) {
                                  _scrubDragStartX = d.localPosition.dx;
                                  _scrubDragStartMs = _currentPos.inMilliseconds
                                      .toDouble();
                                },
                                onPanUpdate: (d) {
                                  if (_scrubDragStartX == null ||
                                      _scrubDragStartMs == null) {
                                    return;
                                  }
                                  // Czułość: 1px = 200ms (nastrojalna)
                                  final deltaPx =
                                      d.localPosition.dx - _scrubDragStartX!;
                                  const sensitivity = 200.0; // ms na piksel
                                  final newMs =
                                      (_scrubDragStartMs! +
                                              deltaPx * sensitivity)
                                          .clamp(
                                            0.0,
                                            _totalDuration.inMilliseconds
                                                .toDouble(),
                                          );
                                  _seekToMs(newMs);
                                },
                                onPanEnd: (_) {
                                  _scrubDragStartX = null;
                                  _scrubDragStartMs = null;
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.swap_horiz,
                                              color: Colors.cyanAccent,
                                              size: 14,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Tryb scrubbing aktywny',
                                              style: TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // ── Kontrolki ─────────────────────────────────────────────────────
        Container(
          color: const Color(0xFF1A1A28),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressBar(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cofnij 5 s
                  IconButton(
                    icon: const Icon(
                      Icons.replay_5,
                      color: Colors.white70,
                      size: 22,
                    ),
                    tooltip: 'Cofnij 5 sekund (Shift + ←) / Rewind 5 seconds (Shift + ←)',
                    onPressed: () {
                      final newMs = (_currentPos.inMilliseconds - 5000).clamp(
                        0,
                        _totalDuration.inMilliseconds,
                      );
                      _seekToMs(newMs.toDouble());
                    },
                  ),
                  // Play / Pause
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 30,
                        color: Colors.white,
                      ),
                      tooltip: _isPlaying
                          ? 'Pauza (Spacja) / Pause (Space)'
                          : 'Odtwarzaj (Spacja) / Play (Space)',
                      onPressed: () =>
                          _isPlaying ? _player.pause() : _player.play(),
                    ),
                  ),
                  // Do przodu 5 s
                  IconButton(
                    icon: const Icon(
                      Icons.forward_5,
                      color: Colors.white70,
                      size: 22,
                    ),
                    tooltip: 'Do przodu 5 sekund (Shift + →) / Forward 5 seconds (Shift + →)',
                    onPressed: () {
                      final newMs = (_currentPos.inMilliseconds + 5000).clamp(
                        0,
                        _totalDuration.inMilliseconds,
                      );
                      _seekToMs(newMs.toDouble());
                    },
                  ),
                  const SizedBox(width: 8),
                  // Przełącznik trybu scrubbing
                  Tooltip(
                    message: _scrubMode
                        ? 'Wyłącz scrubbing (przewijanie myszą po wideo)'
                        : 'Włącz scrubbing (przewijanie myszą po wideo)',
                    child: GestureDetector(
                      onTap: () => setState(() => _scrubMode = !_scrubMode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _scrubMode
                              ? Colors.cyanAccent.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _scrubMode
                                ? Colors.cyanAccent
                                : Colors.white24,
                            width: _scrubMode ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              color: _scrubMode
                                  ? Colors.cyanAccent
                                  : Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Scrubbing',
                              style: TextStyle(
                                color: _scrubMode
                                    ? Colors.cyanAccent
                                    : Colors.white54,
                                fontSize: 11,
                                fontWeight: _scrubMode
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Kontrola prędkości odtwarzania
                  _buildSpeedControl(),
                  const SizedBox(width: 8),
                  // Hint trybu edycji
                  if (widget.isEditMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purpleAccent.withAlpha(100),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.draw,
                            color: Colors.purpleAccent,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tryb edycji: przeciągnij na osi czasu',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
