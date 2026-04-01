import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/analytics_service.dart';
import '../models/action_model.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/action_sidebar.dart';
import '../widgets/focus_player_widget.dart';

class VideoAnalysisScreen extends StatefulWidget {
  final String videoPath;
  const VideoAnalysisScreen({super.key, required this.videoPath});

  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  int? _etaSeconds;
  String? _jobId;
  List<ActionModel> _actions = [];
  ActionModel? _selectedAction;
  Duration _currentPosition = Duration.zero;
  VideoController? _videoController;
  // Video player is loaded only on user request (file is very large)
  bool _videoLoaded = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Check existing analysis in background
    Future.microtask(() => _checkExistingAnalysis());
  }

  Future<void> _checkExistingAnalysis() async {
    // First try reading the local JSON directly (fast, no network)
    final base = widget.videoPath.substring(0, widget.videoPath.lastIndexOf('.'));
    final localFile = File('${base}_analysis.json');
    if (localFile.existsSync()) {
      try {
        final contents = await localFile.readAsString();
        final jsonResponse = jsonDecode(contents);
        final actions = (jsonResponse['actions'] as List)
            .map((v) => ActionModel.fromJson(v))
            .toList();
        if (mounted) {
          setState(() { _actions = actions; });
        }
        return;
      } catch (_) {}
    }
    // Fallback: ask the backend (with timeout)
    try {
      final results = await _analyticsService.getResults(widget.videoPath);
      if (mounted) {
        setState(() { _actions = results; });
      }
    } catch (e) {
      // Not analyzed yet – that's fine
    }
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
    });
    try {
      final id = await _analyticsService.startAnalysis(widget.videoPath);
      if (id == 'completed') {
        _checkExistingAnalysis();
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }
      _jobId = id;
      _pollStatus();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pollStatus() async {
    if (_jobId == null) return;
    bool done = false;
    while (!done) {
      await Future.delayed(const Duration(seconds: 2));
      final statusInfo = await _analyticsService.checkJobStatus(_jobId!);
      final status = statusInfo['status'] as String;
      final progress = (statusInfo['progress'] as num).toDouble();
      final etaRaw = statusInfo['eta_seconds'];
      final eta = etaRaw != null ? (etaRaw as num).toInt() : null;

      if (status == 'completed') {
        done = true;
        _checkExistingAnalysis();
        setState(() {
          _isAnalyzing = false;
          _etaSeconds = null;
        });
      } else if (status == 'error') {
        done = true;
        setState(() {
          _isAnalyzing = false;
          _etaSeconds = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analysis failed in backend.')));
      } else {
        setState(() {
          _analysisProgress = progress;
          _etaSeconds = eta;
        });
      }
    }
  }

  String _formatEta(int? seconds) {
    if (seconds == null) return 'obliczanie...';
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  void _onActionSelected(ActionModel action) {
    setState(() {
      _selectedAction = action;
    });
    if (_videoController != null) {
      _videoController!.player.seek(Duration(milliseconds: action.startMs.round()));
    }
  }

  Future<void> _saveAnalysis() async {
    final base = widget.videoPath.substring(0, widget.videoPath.lastIndexOf('.'));
    final file = File('${base}_analysis.json');
    final jsonString = jsonEncode({
      'actions': _actions.map((a) => a.toJson()).toList(),
    });
    try {
      await file.writeAsString(jsonString);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analiza zapisana poprawnie.')));
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Analytics Dashboard'),
        actions: [
          if (_actions.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.save, color: Colors.greenAccent, size: 20),
              label: const Text('Zapisz analizę', style: TextStyle(color: Colors.white)),
              onPressed: _saveAnalysis,
            ),
          const SizedBox(width: 8),
          if (_isAnalyzing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        value: _analysisProgress,
                        backgroundColor: Colors.white12,
                        color: Colors.purpleAccent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_analysisProgress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      _formatEta(_etaSeconds),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else if (_actions.isEmpty)
            TextButton.icon(
              icon: const Icon(Icons.analytics, color: Colors.purpleAccent),
              label: const Text('Analyze Video', style: TextStyle(color: Colors.white)),
              onPressed: _startAnalysis,
            ),
        ],
      ),
      body: Row(
        children: [
          // Main Video Area
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Stack(
                      children: [
                        // The primary video player
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _videoLoaded
                                ? VideoPlayerWidget(
                                    videoFile: File(widget.videoPath),
                                    actions: _actions,
                                    isEditMode: _isEditMode,
                                    onPositionChanged: (pos) => _currentPosition = pos,
                                    onControllerReady: (controller) => _videoController = controller,
                                    onActionUpdated: (action) {
                                      final idx = _actions.indexWhere((a) => a.id == action.id);
                                      if (idx != -1) {
                                        setState(() {
                                          _actions[idx] = action;
                                        });
                                      }
                                    },
                                    onActionAdded: (action) {
                                      setState(() {
                                        _actions.add(action);
                                        _actions.sort((a, b) => a.startMs.compareTo(b.startMs));
                                      });
                                    },
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.video_file, color: Colors.white30, size: 64),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Wideo nie jest załadowane',
                                          style: TextStyle(color: Colors.white54, fontSize: 16),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Duże pliki wideo ładują się kilkadziesiąt sekund.',
                                          style: TextStyle(color: Colors.white30, fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.play_circle_outline),
                                          label: const Text('Załaduj i odtwórz wideo'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepPurpleAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          ),
                                          onPressed: () => setState(() => _videoLoaded = true),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        // Focus mode picture-in-picture
                        if (_selectedAction != null)
                          Positioned(
                            top: 16,
                            right: 16,
                            width: 200,
                            height: 200,
                            child: FocusPlayerWidget(
                              controller: _videoController!,
                              action: _selectedAction!,
                              mainPosition: _currentPosition,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sidebar
          Container(
            width: 350,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(left: BorderSide(color: Colors.white12)),
            ),
            child: ActionSidebar(
              actions: _actions,
              selectedAction: _selectedAction,
              isEditMode: _isEditMode,
              onEditModeChanged: (val) {
                setState(() => _isEditMode = val);
              },
              onActionSelected: _onActionSelected,
              onActionUpdated: (updatedAction) async {
                try {
                  await _analyticsService.updateAction(widget.videoPath, updatedAction);
                  final idx = _actions.indexWhere((a) => a.id == updatedAction.id);
                  if (idx != -1) {
                    setState(() {
                      _actions[idx] = updatedAction;
                    });
                  }
                } catch(e) {
                   if (!mounted) return;
                   ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
