import 'dart:math';
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/artifact_model.dart';
import '../services/project_data_service.dart';

const double _kNodeW = 160.0;
const double _kNodeH = 72.0;
const double _kProjectNodeW = 180.0;
const double _kProjectNodeH = 80.0;

enum GraphNodeType { project, artifact }

class GraphNode {
  final String id;
  final GraphNodeType type;
  final String label;
  final String? sublabel;
  final Color color;
  final IconData icon;
  Offset position;
  final Object data;

  GraphNode({
    required this.id,
    required this.type,
    required this.label,
    this.sublabel,
    required this.color,
    required this.icon,
    required this.position,
    required this.data,
  });
}

class GraphEdge {
  final String fromId;
  final String toId;
  GraphEdge(this.fromId, this.toId);
}

Color _colorForArtifact(ArtifactType type) {
  switch (type) {
    case ArtifactType.video:    return const Color(0xFF2979FF);
    case ArtifactType.playlist: return const Color(0xFF00C853);
    case ArtifactType.action:   return const Color(0xFFE53935);
  }
}

IconData _iconForArtifact(ArtifactType type) {
  switch (type) {
    case ArtifactType.video:    return Icons.videocam;
    case ArtifactType.playlist: return Icons.playlist_play;
    case ArtifactType.action:   return Icons.bolt;
  }
}

// ─── Edge painter ─────────────────────────────────────────────────────────────

class _EdgePainter extends CustomPainter {
  final List<GraphEdge> edges;
  final Map<String, GraphNode> nodeMap;

  _EdgePainter(this.edges, this.nodeMap);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = nodeMap[edge.fromId];
      final to   = nodeMap[edge.toId];
      if (from == null || to == null) continue;

      final fromW = from.type == GraphNodeType.project ? _kProjectNodeW : _kNodeW;
      final fromH = from.type == GraphNodeType.project ? _kProjectNodeH : _kNodeH;
      final toW   = to.type   == GraphNodeType.project ? _kProjectNodeW : _kNodeW;

      final p1 = Offset(from.position.dx + fromW / 2, from.position.dy + fromH);
      final p2 = Offset(to.position.dx   + toW   / 2, to.position.dy);

      final rect = Rect.fromPoints(p1, p2);
      final safeRect = rect.isEmpty ? Rect.fromLTWH(p1.dx, p1.dy, 1, 1) : rect;
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [from.color.withValues(alpha: 0.7), to.color.withValues(alpha: 0.7)],
      ).createShader(safeRect);

      final ctrl = ((p2.dy - p1.dy) * 0.5).clamp(40.0, 200.0);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(p1.dx, p1.dy + ctrl, p2.dx, p2.dy - ctrl, p2.dx, p2.dy);
      canvas.drawPath(path, paint);

      // arrowhead
      final arrowPaint = Paint()
        ..color = to.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      final arrow = Path()
        ..moveTo(p2.dx, p2.dy)
        ..lineTo(p2.dx - 6, p2.dy - 10)
        ..lineTo(p2.dx + 6, p2.dy - 10)
        ..close();
      canvas.drawPath(arrow, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) => true;
}

// ─── Node widget ─────────────────────────────────────────────────────────────

class _NodeWidget extends StatelessWidget {
  final GraphNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _NodeWidget({
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProject = node.type == GraphNodeType.project;
    final w = isProject ? _kProjectNodeW : _kNodeW;
    final h = isProject ? _kProjectNodeH : _kNodeH;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: w, height: h,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(isProject ? 16 : 12),
            border: Border.all(
              color: isSelected ? Colors.white : node.color.withValues(alpha: 0.8),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: node.color.withValues(alpha: isSelected ? 0.55 : 0.25),
                blurRadius: isSelected ? 20 : 8,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: node.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(node.icon, color: node.color, size: isProject ? 20 : 16),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      node.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isProject ? 13 : 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (node.sublabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  node.sublabel!,
                  style: TextStyle(color: node.color.withValues(alpha: 0.7), fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grid background ──────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    const gs = 40.0;
    for (double x = 0; x < size.width; x += gs) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += gs) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double x = 0; x < size.width; x += gs) {
      for (double y = 0; y < size.height; y += gs) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─── Main GraphView ───────────────────────────────────────────────────────────

class GraphView extends StatefulWidget {
  final List<ProjectModel> projects;
  final VoidCallback? onRefresh;
  final void Function(ProjectModel)? onProjectTap;
  final void Function(ProjectModel)? onProjectEdit;
  final void Function(ProjectModel)? onProjectDelete;

  const GraphView({
    super.key,
    required this.projects,
    this.onRefresh,
    this.onProjectTap,
    this.onProjectEdit,
    this.onProjectDelete,
  });

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  final _dataService = ProjectDataService();
  final _transformCtrl = TransformationController();

  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];
  Map<String, GraphNode> _nodeMap = {};

  String? _selectedId;
  String? _draggingId;   // węzeł aktualnie przeciągany
  bool _isDragging = false;

  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _buildGraph();
    // Auto-center po pierwszym renderze
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitAll();
    });
  }

  @override
  void didUpdateWidget(GraphView old) {
    super.didUpdateWidget(old);
    if (old.projects != widget.projects) _buildGraph();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  // ─── Graph builder ──────────────────────────────────────────────────────────

  void _buildGraph() {
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];

    const startX = 1000.0;
    const startY = 1000.0;
    const projSpacingX = 280.0;
    const artSpacingY  = 110.0;
    const artOffsetY   = 150.0;

    for (int pi = 0; pi < widget.projects.length; pi++) {
      final project = widget.projects[pi];
      final px = startX + pi * projSpacingX;

      nodes.add(GraphNode(
        id: project.id,
        type: GraphNodeType.project,
        label: project.name,
        sublabel: '${project.artifactIds.length} artefaktów',
        color: const Color(0xFF9C27B0),
        icon: Icons.folder_special,
        position: Offset(px, startY),
        data: project,
      ));

      final artifacts = _dataService.artifacts
          .where((a) => project.artifactIds.contains(a.id))
          .toList();

      for (int ai = 0; ai < artifacts.length; ai++) {
        final artifact = artifacts[ai];
        final ax = px - ((artifacts.length - 1) * 90.0) / 2 + ai * 180.0;

        if (!nodes.any((n) => n.id == artifact.id)) {
          nodes.add(GraphNode(
            id: artifact.id,
            type: GraphNodeType.artifact,
            label: artifact.title,
            sublabel: _sublabel(artifact),
            color: _colorForArtifact(artifact.type),
            icon: _iconForArtifact(artifact.type),
            position: Offset(ax, startY + artOffsetY + ai * artSpacingY),
            data: artifact,
          ));
        }
        edges.add(GraphEdge(project.id, artifact.id));
      }
    }

    setState(() {
      _nodes = nodes;
      _edges = edges;
      _nodeMap = {for (final n in nodes) n.id: n};
    });
  }

  String _sublabel(ArtifactModel a) {
    switch (a.type) {
      case ArtifactType.video:    return a.videoCategory ?? 'Wideo';
      case ArtifactType.playlist: return 'Playlista';
      case ArtifactType.action:   return 'Akcja';
    }
  }

  // ─── Fit all ────────────────────────────────────────────────────────────────

  void _fitAll({double? targetScale}) {
    if (_nodes.isEmpty || _viewportSize == Size.zero) return;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final n in _nodes) {
      final w = n.type == GraphNodeType.project ? _kProjectNodeW : _kNodeW;
      final h = n.type == GraphNodeType.project ? _kProjectNodeH : _kNodeH;
      minX = min(minX, n.position.dx);
      minY = min(minY, n.position.dy);
      maxX = max(maxX, n.position.dx + w);
      maxY = max(maxY, n.position.dy + h);
    }

    const pad = 100.0;
    minX -= pad; minY -= pad; maxX += pad; maxY += pad;

    double scale = targetScale ?? min(
      _viewportSize.width  / (maxX - minX),
      _viewportSize.height / (maxY - minY),
    ).clamp(0.15, 2.0);

    final tx = (_viewportSize.width  - (maxX - minX) * scale) / 2 - minX * scale;
    final ty = (_viewportSize.height - (maxY - minY) * scale) / 2 - minY * scale;

    final m = Matrix4.identity();
    m.setEntry(0, 3, tx);
    m.setEntry(1, 3, ty);
    m.setEntry(0, 0, scale);
    m.setEntry(1, 1, scale);
    _transformCtrl.value = m;
  }

  // ─── Pointer-based node dragging ─────────────────────────────────────────────
  // Listener fires BEFORE InteractiveViewer's gesture recognizers,
  // so we can intercept drag without conflicts.

  void _onPointerDown(PointerDownEvent event) {
    final inverseMatrix = Matrix4.inverted(_transformCtrl.value);
    final canvasPos = MatrixUtils.transformPoint(inverseMatrix, event.localPosition);

    for (final node in _nodes.reversed) {
      final w = node.type == GraphNodeType.project ? _kProjectNodeW : _kNodeW;
      final h = node.type == GraphNodeType.project ? _kProjectNodeH : _kNodeH;
      if (Rect.fromLTWH(node.position.dx, node.position.dy, w, h).contains(canvasPos)) {
        _draggingId = node.id;
        setState(() => _isDragging = true);
        return;
      }
    }
    _draggingId = null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_draggingId == null) return;
    final node = _nodeMap[_draggingId!];
    if (node == null) return;
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    setState(() {
      node.position = node.position + event.delta / scale;
      // Rebuild edges dynamically
      _nodeMap[node.id] = node;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _draggingId = null;
    setState(() => _isDragging = false);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _draggingId = null;
    setState(() => _isDragging = false);
  }

  // ─── Context menu ─────────────────────────────────────────────────────────

  void _showContextMenu(BuildContext ctx, GraphNode node) {
    if (node.type != GraphNodeType.project) return;
    final project = node.data as ProjectModel;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    final pos = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    showMenu<void>(
      context: ctx,
      position: RelativeRect.fromLTRB(pos.dx + 60, pos.dy + 20, pos.dx + 60, 0),
      color: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<void>>[
        PopupMenuItem(
          onTap: () => widget.onProjectTap?.call(project),
          child: const Row(children: [
            Icon(Icons.open_in_new, color: Colors.white70, size: 16), SizedBox(width: 10),
            Text('Otwórz projekt', style: TextStyle(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          onTap: () => widget.onProjectEdit?.call(project),
          child: const Row(children: [
            Icon(Icons.edit, color: Colors.white70, size: 16), SizedBox(width: 10),
            Text('Edytuj', style: TextStyle(color: Colors.white)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => widget.onProjectDelete?.call(project),
          child: const Row(children: [
            Icon(Icons.delete_outline, color: Colors.redAccent, size: 16), SizedBox(width: 10),
            Text('Usuń projekt', style: TextStyle(color: Colors.redAccent)),
          ]),
        ),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text('Brak projektów', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    // Używamy stałego, dużego canvasu, aby uniknąć problemów z granicami
    const double canvasSize = 8000.0;

    return Column(
      children: [
        // ── Toolbar ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: const Color(0xFF1A1A2E),
          child: Row(
            children: [
              const Icon(Icons.account_tree, color: Colors.white38, size: 14),
              const SizedBox(width: 8),
              Text(
                '${_nodes.where((n) => n.type == GraphNodeType.project).length} projektów · '
                '${_nodes.where((n) => n.type == GraphNodeType.artifact).length} artefaktów',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              const Text(
                'Przeciągnij węzeł · Dwuklik → otwórz · PPM → menu',
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
              const SizedBox(width: 12),
              // Fit all button
              IconButton(
                icon: const Icon(Icons.zoom_out_map, color: Colors.lightBlueAccent, size: 22),
                tooltip: 'Pokaż wszystko / Fit all',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _fitAll,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.center_focus_strong, color: Colors.white, size: 20),
                tooltip: 'Wyśrodkuj na węzłach (1:1)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _fitAll(targetScale: 1.0),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                tooltip: 'Odśwież graf',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () { _buildGraph(); widget.onRefresh?.call(); },
              ),
            ],
          ),
        ),
        // ── Legend ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: const Color(0xFF141420),
          child: Row(
            children: [
              _legend(Icons.folder_special, const Color(0xFF9C27B0), 'Projekt'),
              const SizedBox(width: 16),
              _legend(Icons.videocam, const Color(0xFF2979FF), 'Wideo'),
              const SizedBox(width: 16),
              _legend(Icons.playlist_play, const Color(0xFF00C853), 'Playlista'),
              const SizedBox(width: 16),
              _legend(Icons.bolt, const Color(0xFFE53935), 'Akcja'),
            ],
          ),
        ),
        // ── Canvas ──────────────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Listener(
                // Pointer events fire before InteractiveViewer's gesture recognizer,
                // so we can grab node drags without conflict.
                onPointerDown:   _onPointerDown,
                onPointerMove:   _onPointerMove,
                onPointerUp:     _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  minScale: 0.02,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(4000),
                  constrained: false,
                  // Disable IV pan/scale while dragging a node
                  panEnabled:   !_isDragging,
                  scaleEnabled: !_isDragging,
                  child: SizedBox(
                    width: canvasSize,
                    height: canvasSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Grid
                        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                        // Edges (repaint every frame during drag)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _EdgePainter(_edges, _nodeMap),
                          ),
                        ),
                        // Nodes
                        ..._nodes.map((node) => Positioned(
                          key: ValueKey(node.id),
                          left: node.position.dx,
                          top:  node.position.dy,
                          child: GestureDetector(
                            onTap: () => setState(() =>
                              _selectedId = _selectedId == node.id ? null : node.id),
                            onDoubleTap: () {
                              if (node.type == GraphNodeType.project) {
                                widget.onProjectTap?.call(node.data as ProjectModel);
                              }
                            },
                            onSecondaryTap: () => _showContextMenu(context, node),
                            child: _NodeWidget(
                              node: node,
                              isSelected: _selectedId == node.id,
                              onTap: () {},
                              onDoubleTap: () {},
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legend(IconData icon, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
    ],
  );
}
