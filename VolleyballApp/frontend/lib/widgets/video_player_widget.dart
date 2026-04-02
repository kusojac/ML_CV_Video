import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/action_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final File videoFile;
  final List<ActionModel> actions;
  final ActionModel? selectedAction;
  final bool isEditMode;
  final Function(Duration) onPositionChanged;
  final Function(VideoController) onControllerReady;
  final ValueChanged<ActionModel>? onActionUpdated;
  final ValueChanged<ActionModel>? onActionAdded;

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
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlayer();
    });
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
      setState(() {
        _totalDuration = dur;
      });
    });

    _player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
      });
    });

    if (!mounted) return;
    setState(() {
      _isInitializing = false;
    });

    widget.onControllerReady(_controller);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _seekToMs(double ms) {
    _player.seek(Duration(milliseconds: ms.round()));
  }

  Widget _buildTimelineMarkers(BoxConstraints constraints) {
    final totalMs = _totalDuration.inMilliseconds.toDouble();
    if (totalMs == 0 || widget.actions.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: widget.actions.map((action) {
        final startFraction = action.startMs / totalMs;
        final endFraction = action.endMs / totalMs;
        final width = ((endFraction - startFraction) * constraints.maxWidth)
            .clamp(2.0, constraints.maxWidth);

        Color color = Colors.purple;
        if (action.type.toUpperCase() == 'BUMP' || action.type == "'Bump'") {
          color = Colors.blueAccent;
        }
        if (action.type.toUpperCase() == 'SET' || action.type == "'Set'") {
          color = Colors.greenAccent;
        }
        if (action.type.toUpperCase() == 'ATTACK' ||
            action.type == "'Right spike'" ||
            action.type == "'Left spike'") {
          color = Colors.redAccent;
        }

        return Positioned(
          left: startFraction * constraints.maxWidth,
          top: 0,
          bottom: 0,
          width: width,
          child: GestureDetector(
            onHorizontalDragUpdate: widget.isEditMode ? (details) {
              final double msDelta = (details.primaryDelta ?? 0) / constraints.maxWidth * totalMs;
              final newStartMs = (action.startMs + msDelta).clamp(0.0, totalMs);
              final newEndMs = (action.endMs + msDelta).clamp(newStartMs, totalMs);
              final updated = ActionModel(
                id: action.id,
                type: action.type,
                startMs: newStartMs,
                endMs: newEndMs,
                playerBox: action.playerBox,
                playerId: action.playerId,
                confidence: action.confidence,
              );
              widget.onActionUpdated?.call(updated);
            } : null,
            onTap: () => _seekToMs(action.startMs),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: widget.isEditMode ? 0.9 : 0.7),
                borderRadius: BorderRadius.circular(widget.isEditMode ? 6 : 4),
                border: widget.isEditMode ? Border.all(color: Colors.white54, width: 1.5) : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _player.stream.position,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final total = _totalDuration;
        final progress = total.inMilliseconds > 0
            ? pos.inMilliseconds / total.inMilliseconds
            : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background track
                Container(
                  height: 24,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                ),
                // Buffered / played
                Container(
                  height: 24,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(12)),
                ),
                // Action markers
                SizedBox(height: 24, child: _buildTimelineMarkers(constraints)),
                // Scrub gesture
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    final rel =
                        (details.localPosition.dx / constraints.maxWidth).clamp(
                          0.0,
                          1.0,
                        );
                    _seekToMs(rel * total.inMilliseconds.toDouble());
                  },
                  onTapUp: (details) {
                    final rel =
                        (details.localPosition.dx / constraints.maxWidth).clamp(
                          0.0,
                          1.0,
                        );
                    final targetMs = rel * total.inMilliseconds.toDouble();
                    if (widget.isEditMode) {
                      final newAction = ActionModel(
                        id: 'action_m_${DateTime.now().millisecondsSinceEpoch}',
                        type: 'Set',
                        startMs: targetMs,
                        endMs: (targetMs + 1000.0).clamp(0.0, total.inMilliseconds.toDouble()),
                        playerBox: [0.0, 0.0, 0.0, 0.0],
                        playerId: 'Unknown',
                        confidence: 1.0,
                      );
                      widget.onActionAdded?.call(newAction);
                    } else {
                      _seekToMs(targetMs);
                    }
                  },
                  child: const SizedBox(height: 24, width: double.infinity),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final videoW = _controller.player.state.width?.toDouble() ?? 1920.0;
              final videoH = _controller.player.state.height?.toDouble() ?? 1080.0;
              final bool drawing = widget.isEditMode && widget.selectedAction != null;

              return Center(
                child: AspectRatio(
                  aspectRatio: videoW / videoH,
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      final size = Size(boxConstraints.maxWidth, boxConstraints.maxHeight);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Video(controller: _controller),
                          if (drawing)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                setState(() {
                                  _dragStart = details.localPosition;
                                  _dragCurrent = details.localPosition;
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  _dragCurrent = details.localPosition;
                                });
                              },
                              onPanEnd: (details) {
                                if (_dragStart != null && _dragCurrent != null) {
                                  final x1 = _dragStart!.dx / size.width * videoW;
                                  final y1 = _dragStart!.dy / size.height * videoH;
                                  final x2 = _dragCurrent!.dx / size.width * videoW;
                                  final y2 = _dragCurrent!.dy / size.height * videoH;

                                  final bxMin = x1 < x2 ? x1 : x2;
                                  final bxMax = x1 > x2 ? x1 : x2;
                                  final byMin = y1 < y2 ? y1 : y2;
                                  final byMax = y1 > y2 ? y1 : y2;

                                  if (bxMax - bxMin > 10 && byMax - byMin > 10) {
                                    final updated = ActionModel(
                                      id: widget.selectedAction!.id,
                                      type: widget.selectedAction!.type,
                                      startMs: widget.selectedAction!.startMs,
                                      endMs: widget.selectedAction!.endMs,
                                      playerBox: [bxMin, byMin, bxMax, byMax],
                                      playerId: widget.selectedAction!.playerId,
                                      confidence: widget.selectedAction!.confidence,
                                    );
                                    widget.onActionUpdated?.call(updated);
                                  }
                                }
                                setState(() {
                                  _dragStart = null;
                                  _dragCurrent = null;
                                });
                              },
                            ),
                          if (drawing && _dragStart != null && _dragCurrent != null)
                            Positioned(
                              left: _dragStart!.dx < _dragCurrent!.dx ? _dragStart!.dx : _dragCurrent!.dx,
                              top: _dragStart!.dy < _dragCurrent!.dy ? _dragStart!.dy : _dragCurrent!.dy,
                              width: (_dragCurrent!.dx - _dragStart!.dx).abs(),
                              height: (_dragCurrent!.dy - _dragStart!.dy).abs(),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.redAccent, width: 2),
                                  color: Colors.redAccent.withValues(alpha: 0.2),
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
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressBar(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _isPlaying ? _player.pause() : _player.play();
                    },
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
