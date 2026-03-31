import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/action_model.dart';

class FocusPlayerWidget extends StatefulWidget {
  final File videoFile;
  final ActionModel action;
  final Duration mainPosition;

  const FocusPlayerWidget({
    super.key,
    required this.videoFile,
    required this.action,
    required this.mainPosition,
  });

  @override
  State<FocusPlayerWidget> createState() => _FocusPlayerWidgetState();
}

class _FocusPlayerWidgetState extends State<FocusPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        // Sync to main position
        _controller.seekTo(widget.mainPosition);
        _controller.play();
        _controller.setVolume(0.0); // Mute the PIP
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant FocusPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action.id != widget.action.id || oldWidget.videoFile.path != widget.videoFile.path) {
      _controller.dispose();
      _controller = VideoPlayerController.file(widget.videoFile)
        ..initialize().then((_) {
          _controller.seekTo(widget.mainPosition);
          _controller.play();
          _controller.setVolume(0.0);
          setState(() {});
        });
    } else {
      // Soft sync
      final diff = _controller.value.position.inMilliseconds - widget.mainPosition.inMilliseconds;
      if (diff.abs() > 300) {
         _controller.seekTo(widget.mainPosition);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(
        color: Colors.black54,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent)),
      );
    }
    
    // playerBox is [x_min, y_min, x_max, y_max].
    // Note: The python API `engine.py` gives `[x_min, y_min, x_max, y_max]`.
    if (widget.action.playerBox.length != 4) return const SizedBox.shrink();
    
    final vw = _controller.value.size.width;
    final vh = _controller.value.size.height;
    
    if (vw == 0 || vh == 0) return const SizedBox.shrink();

    final bxMin = widget.action.playerBox[0];
    final byMin = widget.action.playerBox[1];
    final bxMax = widget.action.playerBox[2];
    final byMax = widget.action.playerBox[3];

    // Bounding box size
    final bw = (bxMax - bxMin).clamp(1.0, vw);
    final bh = (byMax - byMin).clamp(1.0, vh);

    // To crop, we scale up the video by vw/bw and vh/bh.
    final scaleX = vw / bw;
    final scaleY = vh / bh;
    
    // Choose the max scale to maintain aspect ratio, or scale proportionally
    final scale = scaleX > scaleY ? scaleY : scaleX;

    // Center of the bounding box
    final centerX = bxMin + bw / 2;
    final centerY = byMin + bh / 2;

    // Fractional offset for alignment (0.0 to 1.0)
    final fractionalX = (centerX / vw).clamp(0.0, 1.0);
    final fractionalY = (centerY / vh).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.purpleAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: FractionalOffset(fractionalX, fractionalY),
                child: Transform.scale(
                  scale: scale * 1.5, // 1.5 zoom margin
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),
            // Floating label
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.purpleAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.action.playerId == 'Unknown' ? 'Player Focus' : 'Player ${widget.action.playerId}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
