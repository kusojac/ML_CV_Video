import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/action_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final File videoFile;
  final List<ActionModel> actions;
  final bool isEditMode;
  final Function(Duration) onPositionChanged;
  final Function(VideoController) onControllerReady;
  final ValueChanged<ActionModel>? onActionUpdated;
  final ValueChanged<ActionModel>? onActionAdded;

  const VideoPlayerWidget({
    super.key,
    required this.videoFile,
    required this.actions,
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
            child: Container(color: color.withValues(alpha: widget.isEditMode ? 0.9 : 0.6)),
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
                Container(height: 10, color: Colors.white24),
                // Buffered / played
                Container(
                  height: 10,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  color: Colors.deepPurpleAccent,
                ),
                // Action markers
                SizedBox(height: 10, child: _buildTimelineMarkers(constraints)),
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
                  child: const SizedBox(height: 10, width: double.infinity),
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
        Expanded(child: Video(controller: _controller)),
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
