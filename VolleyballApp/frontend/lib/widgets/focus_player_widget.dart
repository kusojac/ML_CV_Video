import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/action_model.dart';

class FocusPlayerWidget extends StatefulWidget {
  final VideoController controller;
  final ActionModel action;
  final Duration mainPosition;

  const FocusPlayerWidget({
    super.key,
    required this.controller,
    required this.action,
    required this.mainPosition,
  });

  @override
  State<FocusPlayerWidget> createState() => _FocusPlayerWidgetState();
}

class _FocusPlayerWidgetState extends State<FocusPlayerWidget> {
  Size _videoSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initSizeListener();
  }

  void _initSizeListener() {
    final w = widget.controller.player.state.width;
    final h = widget.controller.player.state.height;
    if (w != null && h != null) {
      _videoSize = Size(w.toDouble(), h.toDouble());
    }

    widget.controller.player.stream.width.listen((w) {
      if (!mounted) return;
      if (w != null && w > 0) {
        setState(() {
          _videoSize = Size(w.toDouble(), _videoSize.height);
        });
      }
    });

    widget.controller.player.stream.height.listen((h) {
      if (!mounted) return;
      if (h != null && h > 0) {
        setState(() {
          _videoSize = Size(_videoSize.width, h.toDouble());
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant FocusPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _initSizeListener();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoSize.width == 0 || _videoSize.height == 0) {
       final w = widget.controller.player.state.width;
       final h = widget.controller.player.state.height;
       if (w != null && h != null && w > 0 && h > 0) {
         _videoSize = Size(w.toDouble(), h.toDouble());
       } else {
         return Container(
           color: Colors.black54,
           child: const Center(
             child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
           ),
         );
       }
    }

    // playerBox is [x_min, y_min, x_max, y_max].
    if (widget.action.playerBox.length != 4) return const SizedBox.shrink();

    final vw = _videoSize.width;
    final vh = _videoSize.height;

    final bxMin = widget.action.playerBox[0];
    final byMin = widget.action.playerBox[1];
    final bxMax = widget.action.playerBox[2];
    final byMax = widget.action.playerBox[3];

    // Bounding box size
    final bw = (bxMax - bxMin).clamp(1.0, vw);
    final bh = (byMax - byMin).clamp(1.0, vh);

    // Scale up the video so the bounding box fills the widget
    final scaleX = vw / bw;
    final scaleY = vh / bh;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final safeScale = (scale * 1.5).clamp(1.0, 20.0);

    // Center of the bounding box as fractional offset (0..1)
    final centerX = bxMin + bw / 2;
    final centerY = byMin + bh / 2;
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
              child: Transform.scale(
                scale: safeScale,
                alignment: FractionalOffset(fractionalX, fractionalY),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: vw,
                    height: vh,
                    child: Video(controller: widget.controller),
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
                      widget.action.playerId == 'Unknown'
                          ? 'Player Focus'
                          : 'Player ${widget.action.playerId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
