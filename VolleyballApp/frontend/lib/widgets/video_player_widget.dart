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
  final ValueChanged<ActionModel>? onActionSelected;
  final List<ActionModel>? playlistActions;
  final ValueChanged<ActionModel>? onActionPlaylistToggled;

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
  double? _rangeStartMs;   // punkt startowy zaznaczenia (ms)
  double? _rangeEndMs;     // punkt końcowy zaznaczenia (ms)
  bool _isDraggingRange = false;

  // Poziom przybliżenia (zoom) osi czasu
  double _zoomLevel = 1.0;

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
    super.dispose();
  }

  void _seekToMs(double ms) =>
      _player.seek(Duration(milliseconds: ms.round()));

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline,
                  color: Colors.purpleAccent, size: 22),
              const SizedBox(width: 10),
              const Text('Nowa akcja',
                  style: TextStyle(color: Colors.white, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zakres czasu
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
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
                        const Text('Początek',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        Text(
                          _fmtMs(startMs),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 15),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward,
                        color: Colors.white38, size: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Koniec',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        Text(
                          _fmtMs(endMs),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Typ akcji',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              // Przyciski wyboru typu
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kVolleyballActions.map((type) {
                  final isChosen = type == selectedType;
                  final col = _actionColor(type);
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj',
                  style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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

  String _fmtMs(double ms) {
    final d = Duration(milliseconds: ms.round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final mil =
        (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s.$mil' : '$m:$s.$mil';
  }

  // ─── Markery na timeline ──────────────────────────────────────────────────

  Widget _buildTimelineMarkers(double timelineWidth) {
    final totalMs = _totalDuration.inMilliseconds.toDouble();
    if (totalMs == 0) return const SizedBox.shrink();

    final markers = <Widget>[];

    // Istniejące akcje
    for (final action in widget.actions) {
      final startFrac = (action.startMs / totalMs).clamp(0.0, 1.0);
      final endFrac = (action.endMs / totalMs).clamp(0.0, 1.0);
      final w =
          ((endFrac - startFrac) * timelineWidth).clamp(2.0, timelineWidth);
      final color = _actionColor(action.type);
      final isSelected = widget.selectedAction?.id == action.id;
      final isInPlaylist = widget.playlistActions?.any((a) => a.id == action.id) ?? false;

      markers.add(
        Positioned(
          left: startFrac * timelineWidth,
          top: 0,
          bottom: 0,
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
              onHorizontalDragUpdate: widget.isEditMode ? (details) {
                      final msDelta =
                          (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                      final newStart =
                          (action.startMs + msDelta).clamp(0.0, totalMs);
                      final newEnd =
                          (action.endMs + msDelta).clamp(newStart, totalMs);
                          
                      _seekToMs(newStart); // Podgląd
                      
                      widget.onActionUpdated?.call(ActionModel(
                        id: action.id,
                        type: action.type,
                        startMs: newStart,
                        endMs: newEnd,
                        playerBox: action.playerBox,
                        playerId: action.playerId,
                        confidence: action.confidence,
                      ));
                    } : null,
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
                  // Blok akcji
                  Container(
                    decoration: BoxDecoration(
                      color: color.withAlpha(widget.isEditMode || _hoveredActionId == action.id ? 204 : 153),
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
                // Nazwa akcji (jeśli wystarczająco szeroka)
                if (w > 30)
                  Center(
                    child: Text(
                      action.type.substring(0, action.type.length.clamp(0, 3)),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(180),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Uchwyt lewej krawędzi
                if (widget.isEditMode) // Pokazuj uchwyty tylko w trybie edycji
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 12,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          final msDelta =
                              (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                          final newStart =
                              (action.startMs + msDelta).clamp(0.0, action.endMs - 100);
                          
                          _seekToMs(newStart); // Podgląd
                          
                          widget.onActionUpdated?.call(ActionModel(
                            id: action.id,
                            type: action.type,
                            startMs: newStart,
                            endMs: action.endMs,
                            playerBox: action.playerBox,
                            playerId: action.playerId,
                            confidence: action.confidence,
                          ));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Uchwyt prawej krawędzi
                if (widget.isEditMode) // Pokazuj uchwyty tylko w trybie edycji
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 12,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          final msDelta =
                              (details.primaryDelta ?? 0) / timelineWidth * totalMs;
                          final newEnd =
                              (action.endMs + msDelta).clamp(action.startMs + 100, totalMs);
                          
                          _seekToMs(newEnd); // Podgląd
                          
                          widget.onActionUpdated?.call(ActionModel(
                            id: action.id,
                            type: action.type,
                            startMs: action.startMs,
                            endMs: newEnd,
                            playerBox: action.playerBox,
                            playerId: action.playerId,
                            confidence: action.confidence,
                          ));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ));
    }

    // Podgląd zaznaczanego zakresu (podczas drag)
    if (_isDraggingRange &&
        _rangeStartMs != null &&
        _rangeEndMs != null &&
        _totalDuration.inMilliseconds > 0) {
      final lo = _rangeStartMs!.clamp(0.0, totalMs);
      final hi = _rangeEndMs!.clamp(0.0, totalMs);
      final left = (lo / totalMs * timelineWidth).clamp(0.0, timelineWidth);
      final right = (hi / totalMs * timelineWidth).clamp(0.0, timelineWidth);
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
              border: Border.all(
                color: Colors.purpleAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      );

      // Linia pionowa — lewy uchwyt
      markers.add(
        Positioned(
          left: selLeft,
          top: -4,
          bottom: -4,
          width: 2,
          child: Container(color: Colors.purpleAccent),
        ),
      );

      // Linia pionowa — prawy uchwyt
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
        final progress =
            totalMs > 0 ? pos.inMilliseconds / totalMs : 0.0;

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
                          fontFamily: 'monospace'),
                    ),
                    if (widget.isEditMode)
                      Row(
                        children: [
                          const Icon(Icons.touch_app,
                              color: Colors.purpleAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _rangeStartMs != null && _rangeEndMs != null
                                ? '${_fmtMs(_rangeStartMs!.clamp(0.0, totalMs))} → '
                                    '${_fmtMs(_rangeEndMs!.clamp(0.0, totalMs))}'
                                : 'Przeciągnij aby dodać akcję',
                            style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 11,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        if (_zoomLevel > 1.0)
                          Text('Zoom: ${_zoomLevel.toStringAsFixed(1)}x',
                              style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        if (_zoomLevel > 1.0) const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.zoom_out, color: Colors.white54, size: 14),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.5).clamp(1.0, 10.0)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.zoom_in, color: Colors.white54, size: 14),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.5).clamp(1.0, 10.0)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _fmtMs(totalMs),
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Pasek timeline z gesture
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: _isDraggingRange ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // ── Ruch / przewijanie (bez edit mode) ───────────────────
                    onHorizontalDragUpdate: widget.isEditMode
                        ? null
                        : (details) {
                            final rel =
                                (details.localPosition.dx / timelineWidth)
                                    .clamp(0.0, 1.0);
                            _seekToMs(rel * totalMs);
                          },
                  // ── Tap bez edit: seek ─────────────────────────────────
                  onTapUp: widget.isEditMode
                      ? null
                      : (details) {
                          final rel =
                              (details.localPosition.dx / timelineWidth)
                                  .clamp(0.0, 1.0);
                          _seekToMs(rel * totalMs);
                        },
                  // ── Drag w edit: zaznaczenie zakresu ──────────────────
                  onPanStart: widget.isEditMode
                      ? (details) {
                          final ms =
                              (details.localPosition.dx / timelineWidth)
                                      .clamp(0.0, 1.0) *
                                  totalMs;
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
                          final ms =
                              (details.localPosition.dx / timelineWidth)
                                      .clamp(0.0, 1.0) *
                                  totalMs;
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
                            await _confirmNewAction(start, end);
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
              ],
            );
          },
        );
      },
    );
  }

  // ─── Bounding box na wideo ────────────────────────────────────────────────

  Widget _buildVideoBoundingBoxOverlay(Size size, double videoW, double videoH) {
    if (!widget.isEditMode || widget.selectedAction == null) {
      return const SizedBox.shrink();
    }
    return Stack(
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
                  border: Border.all(color: Colors.redAccent, width: 2),
                  color: Colors.redAccent.withAlpha(51),
                ),
              ),
            ),
          )
        else if (widget.selectedAction != null &&
            widget.selectedAction!.playerBox.length == 4 &&
            widget.selectedAction!.playerBox.any((v) => v != 0.0))
          Positioned(
            left: widget.selectedAction!.playerBox[0] / videoW * size.width,
            top: widget.selectedAction!.playerBox[1] / videoH * size.height,
            width: ((widget.selectedAction!.playerBox[2] -
                        widget.selectedAction!.playerBox[0]) /
                    videoW *
                    size.width)
                .abs(),
            height: ((widget.selectedAction!.playerBox[3] -
                        widget.selectedAction!.playerBox[1]) /
                    videoH *
                    size.height)
                .abs(),
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  color: Colors.greenAccent.withAlpha(51),
                ),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Text(
                      'Fokus',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
            Text('Ładowanie wideo...',
                style: TextStyle(color: Colors.white54)),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                    icon: const Icon(Icons.replay_5,
                        color: Colors.white70, size: 22),
                    onPressed: () {
                      final newMs = (_currentPos.inMilliseconds - 5000)
                          .clamp(0, _totalDuration.inMilliseconds);
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
                      onPressed: () =>
                          _isPlaying ? _player.pause() : _player.play(),
                    ),
                  ),
                  // Do przodu 5 s
                  IconButton(
                    icon: const Icon(Icons.forward_5,
                        color: Colors.white70, size: 22),
                    onPressed: () {
                      final newMs = (_currentPos.inMilliseconds + 5000)
                          .clamp(0, _totalDuration.inMilliseconds);
                      _seekToMs(newMs.toDouble());
                    },
                  ),
                  const SizedBox(width: 16),
                  // Hint trybu edycji
                  if (widget.isEditMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.purpleAccent.withAlpha(100)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.draw,
                              color: Colors.purpleAccent, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Tryb edycji: przeciągnij na osi czasu',
                            style: TextStyle(
                                color: Colors.purpleAccent, fontSize: 11),
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
