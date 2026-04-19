import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/action_model.dart';

class FocusPlayerWidget extends StatefulWidget {
  final VideoController controller;
  final ActionModel action;
  final Duration mainPosition;
  final VoidCallback? onResetFocus;
  final bool isUpdatingFocus;

  const FocusPlayerWidget({
    super.key,
    required this.controller,
    required this.action,
    required this.mainPosition,
    this.onResetFocus,
    this.isUpdatingFocus = false,
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

    return GestureDetector(
      onDoubleTap: widget.onResetFocus,
      child: AspectRatio(
        aspectRatio: bw / bh,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
                color: widget.isUpdatingFocus ? Colors.amberAccent : Colors.purpleAccent,
                width: widget.isUpdatingFocus ? 3 : 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final W = constraints.maxWidth;
                final H = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Stack(
                      children: [
                        Positioned(
                          left: -(bxMin / bw) * W,
                          top: -(byMin / bh) * H,
                          width: (vw / bw) * W,
                          height: (vh / bh) * H,
                          child: Video(controller: widget.controller),
                        ),
                      ],
                    ),
                    if (widget.isUpdatingFocus)
                      Container(
                        color: Colors.black.withAlpha(100),
                        child: const Center(
                          child: Text(
                            'Narysuj nowy\nobszar na wideo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
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
                          color: widget.isUpdatingFocus ? Colors.amber.withAlpha(200) : Colors.black.withAlpha(180),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              widget.isUpdatingFocus
                                  ? 'Edycja obszaru...'
                                  : (widget.action.playerId == 'Unknown'
                                      ? 'Player Focus'
                                      : 'Player ${widget.action.playerId}'),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
