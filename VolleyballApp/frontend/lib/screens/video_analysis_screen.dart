import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/analytics_service.dart';
import '../services/analysis_file_service.dart';
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
  // JSON state
  bool _hasUnsavedChanges = false;
  String? _loadedFromPath; // null = default path obok wideo

  // Filtrowanie
  String _filterType = 'All';
  String _filterPlayer = 'All';
  bool _isolateSelected = false;

  List<ActionModel> get _filteredActions {
    return _actions.where((a) {
      if (_isEditMode && _isolateSelected && _selectedAction != null) {
        if (a.id != _selectedAction!.id) return false;
      }
      if (_filterType != 'All' && a.type != _filterType) return false;
      if (_filterPlayer != 'All' && a.playerId != _filterPlayer) return false;
      return true;
    }).toList();
  }
  
  // Pozycja okienka PIP (Player Focus)
  double _focusPlayerTop = 16.0;
  double _focusPlayerRight = 16.0;
  double _focusPlayerWidth = 200.0;
  
  bool _isUpdatingFocus = false;

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

  // ─── Zapis ─────────────────────────────────────────────────────────────────

  /// Zapisuje do domyślnego miejsca (obok wideo)
  Future<void> _saveAnalysis() async {
    try {
      await AnalysisFileService.saveToDefault(
        videoPath: widget.videoPath,
        actions: _actions,
      );
      if (!mounted) return;
      setState(() {
        _hasUnsavedChanges = false;
        _loadedFromPath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Analiza zapisana obok wideo.'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
      }
    }
  }

  /// Otwiera dialog "Zapisz jako" i pozwala wybrać lokalizację
  Future<void> _saveAnalysisAs() async {
    try {
      final savedPath = await AnalysisFileService.saveAs(
        videoPath: widget.videoPath,
        actions: _actions,
      );
      if (savedPath == null) return; // anulowano
      if (!mounted) return;
      setState(() {
        _hasUnsavedChanges = false;
        _loadedFromPath = savedPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zapisano: ${savedPath.split(Platform.pathSeparator).last}'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
      }
    }
  }

  // ─── Ładowanie ─────────────────────────────────────────────────────────────

  /// Ładuje wyniki z pliku wybranego przez użytkownika (file picker)
  Future<void> _loadFromFile() async {
    if (_hasUnsavedChanges) {
      final proceed = await _confirmDiscardChanges();
      if (proceed != true) return;
    }
    try {
      final result = await AnalysisFileService.loadFromPicker();
      if (result == null) return; // anulowano
      if (!mounted) return;
      setState(() {
        _actions = result.actions;
        _selectedAction = null;
        _hasUnsavedChanges = false;
        _loadedFromPath = result.sourcePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wczytano ${result.actions.length} akcji'
            ' z: ${result.sourcePath.split(Platform.pathSeparator).last}',
          ),
          backgroundColor: const Color(0xFF0D47A1),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd odczytu: $e')));
      }
    }
  }

  // ─── Usunięcie ─────────────────────────────────────────────────────────────

  Future<void> _deleteAnalysis() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text('Usuń analizę', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Czy na pewno chcesz usunąć wszystkie wyniki analizy?\n'
          'Plik JSON zostanie skasowany z dysku.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final file = File(AnalysisFileService.defaultJsonPath(widget.videoPath));
    try {
      if (file.existsSync()) file.deleteSync();
      if (mounted) {
        setState(() {
          _actions.clear();
          _selectedAction = null;
          _hasUnsavedChanges = false;
          _loadedFromPath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analiza została usunięta.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd usuwania: $e')));
      }
    }
  }

  // ─── Pomocnicze ─────────────────────────────────────────────────────────────

  Future<bool?> _confirmDiscardChanges() => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: const Text('Niezapisane zmiany',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Masz niezapisane zmiany. Czy na pewno chcesz je odrzucić?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Anuluj', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Odrzuć',
                  style: TextStyle(color: Colors.orangeAccent)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Video Analytics Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (_loadedFromPath != null)
              Text(
                _loadedFromPath!.split(Platform.pathSeparator).last,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // ── Przyciski ładowania/zapisu jeśli są już akcje ───────────────
          if (_actions.isNotEmpty) ...[
            // Wskaźnik niezapisanych zmian
            if (_hasUnsavedChanges)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                child: Tooltip(
                  message: 'Niezapisane zmiany',
                  child: Icon(Icons.circle, color: Colors.orangeAccent, size: 10),
                ),
              ),
            // Menu zapisu
            PopupMenuButton<String>(
              tooltip: 'Opcje zapisu',
              icon: Icon(
                Icons.save_alt,
                color: _hasUnsavedChanges ? Colors.orangeAccent : Colors.greenAccent,
                size: 22,
              ),
              color: const Color(0xFF2A2A3E),
              onSelected: (v) {
                if (v == 'save') _saveAnalysis();
                if (v == 'save_as') _saveAnalysisAs();
                if (v == 'delete') _deleteAnalysis();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'save',
                  child: Row(children: [
                    Icon(Icons.save, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Zapisz obok wideo', style: TextStyle(color: Colors.white)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'save_as',
                  child: Row(children: [
                    Icon(Icons.save_as, color: Colors.lightBlueAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Zapisz jako...', style: TextStyle(color: Colors.white)),
                  ]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Usuń analizę', style: TextStyle(color: Colors.redAccent)),
                  ]),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          // ── Przycisk wczytaj z pliku (zawsze widoczny) ──────────────────
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.amberAccent, size: 22),
            tooltip: 'Wczytaj wyniki z pliku JSON...',
            onPressed: _loadFromFile,
          ),
          const SizedBox(width: 4),
          // ── Pasek postępu analizy lub przycisk "Analyze" ───────────────
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.timer_outlined,
                        size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      _formatEta(_etaSeconds),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else if (_actions.isEmpty)
            TextButton.icon(
              icon: const Icon(Icons.analytics, color: Colors.purpleAccent),
              label: const Text('Analyze Video',
                  style: TextStyle(color: Colors.white)),
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
                                    actions: _filteredActions,
                                    selectedAction: _selectedAction,
                                    isEditMode: _isEditMode,
                                    onPositionChanged: (pos) => _currentPosition = pos,
                                    onControllerReady: (controller) => _videoController = controller,
                                    onActionSelected: _onActionSelected,
                                    onActionUpdated: (action) {
                                      final idx = _actions.indexWhere((a) => a.id == action.id);
                                      if (idx != -1) {
                                        setState(() {
                                          _actions[idx] = action;
                                          if (_selectedAction?.id == action.id) {
                                            _selectedAction = action;
                                          }
                                        });
                                      }
                                      setState(() {
                                        _isUpdatingFocus = false;
                                      });
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
                            top: _focusPlayerTop,
                            right: _focusPlayerRight,
                            width: _focusPlayerWidth,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _focusPlayerTop += details.delta.dy;
                                      _focusPlayerRight -= details.delta.dx;
                                    });
                                  },
                                  child: FocusPlayerWidget(
                                    controller: _videoController!,
                                    action: _selectedAction!,
                                    mainPosition: _currentPosition,
                                    isUpdatingFocus: _isUpdatingFocus,
                                    onResetFocus: _isEditMode
                                        ? () {
                                            // Start updating focus mode instead of resetting action to 0
                                            setState(() {
                                              _isUpdatingFocus = true;
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                                // Uchwyt do zmiany rozmiaru (lewy dolny róg)
                                Positioned(
                                  bottom: -10,
                                  left: -10,
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        // delta.dx ujemna => ruch w lewo => szerokość rośnie
                                        _focusPlayerWidth = (_focusPlayerWidth - details.delta.dx).clamp(100.0, 800.0);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.purpleAccent,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.open_in_full, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
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
              filterType: _filterType,
              filterPlayer: _filterPlayer,
              onFilterTypeChanged: (v) => setState(() => _filterType = v),
              onFilterPlayerChanged: (v) => setState(() => _filterPlayer = v),
              isolateSelected: _isolateSelected,
              onIsolateSelectedChanged: (v) => setState(() => _isolateSelected = v),
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
