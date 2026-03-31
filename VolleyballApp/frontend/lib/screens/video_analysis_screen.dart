import 'package:flutter/material.dart';
import 'dart:io';
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
  String? _jobId;
  List<ActionModel> _actions = [];
  ActionModel? _selectedAction;
  Duration _currentPosition = Duration.zero;
  void Function(Duration)? _seekTo;

  @override
  void initState() {
    super.initState();
    _checkExistingAnalysis();
  }

  Future<void> _checkExistingAnalysis() async {
    try {
      final results = await _analyticsService.getResults(widget.videoPath);
      setState(() {
        _actions = results;
      });
    } catch (e) {
      // Not analyzed yet
    }
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
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
      final status = await _analyticsService.checkJobStatus(_jobId!);
      if (status == 'completed') {
        done = true;
        _checkExistingAnalysis();
        setState(() {
          _isAnalyzing = false;
        });
      } else if (status == 'error') {
        done = true;
        setState(() {
          _isAnalyzing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analysis failed in backend.')));
      }
    }
  }

  void _onActionSelected(ActionModel action) {
    setState(() {
      _selectedAction = action;
    });
    if (_seekTo != null) {
      _seekTo!(Duration(milliseconds: action.startMs.round()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Analytics Dashboard'),
        actions: [
          if (_isAnalyzing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
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
                            child: VideoPlayerWidget(
                              videoFile: File(widget.videoPath),
                              actions: _actions,
                              onPositionChanged: (pos) => _currentPosition = pos,
                              onControllerReady: (seekFn) => _seekTo = seekFn,
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
                              videoFile: File(widget.videoPath),
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
