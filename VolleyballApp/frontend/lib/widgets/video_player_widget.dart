import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/action_model.dart';
class VideoPlayerWidget extends StatefulWidget {
  final File videoFile;
  final List<ActionModel> actions;
  final Function(Duration) onPositionChanged;
  final Function(void Function(Duration)) onControllerReady;

  const VideoPlayerWidget({
    super.key,
    required this.videoFile,
    required this.actions,
    required this.onPositionChanged,
    required this.onControllerReady,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  Duration _currentPos = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        widget.onControllerReady(_controller.seekTo);
      });
    _controller.addListener(() {
      final pos = _controller.value.position;
      if (_currentPos != pos) {
        _currentPos = pos;
        widget.onPositionChanged(pos);
        setState(() {});
      }
      if (_isPlaying != _controller.value.isPlaying) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seekToMs(double ms) {
    _controller.seekTo(Duration(milliseconds: ms.round()));
  }

  Widget _buildTimelineMarkers() {
    if (!_controller.value.isInitialized || widget.actions.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalDuration = _controller.value.duration.inMilliseconds.toDouble();
        if (totalDuration == 0) return const SizedBox.shrink();

        return Stack(
          children: widget.actions.map((action) {
            final startFraction = action.startMs / totalDuration;
            final endFraction = action.endMs / totalDuration;
            final width = ((endFraction - startFraction) * constraints.maxWidth).clamp(2.0, constraints.maxWidth);

            Color color = Colors.purple;
            if (action.type.toUpperCase() == 'BUMP' || action.type == "'Bump'") color = Colors.blueAccent;
            if (action.type.toUpperCase() == 'SET' || action.type == "'Set'") color = Colors.greenAccent;
            if (action.type.toUpperCase() == 'ATTACK' || action.type == "'Right spike'" || action.type == "'Left spike'") color = Colors.redAccent;

            return Positioned(
              left: startFraction * constraints.maxWidth,
              top: 0,
              bottom: 0,
              width: width,
              child: GestureDetector(
                onTap: () => _seekToMs(action.startMs),
                child: Container(
                  color: color.withValues(alpha: 0.6),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.deepPurpleAccent,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white38,
                      ),
                    ),
                    _buildTimelineMarkers(),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 32, color: Colors.white),
                    onPressed: () {
                      _isPlaying ? _controller.pause() : _controller.play();
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
