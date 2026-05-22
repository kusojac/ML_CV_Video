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
import '../models/artifact_model.dart';
import '../services/project_data_service.dart';

class VideoAnalysisScreen extends StatefulWidget {
  final String videoPath;
  final AnalyticsService? analyticsService;
  final String? projectId;
  final String? initialPlaylistPath;

  const VideoAnalysisScreen({
    super.key,
    required this.videoPath,
    this.analyticsService,
    this.projectId,
    this.initialPlaylistPath,
  });

  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  late final AnalyticsService _analyticsService;
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  int? _etaSeconds;
  String? _jobId;
  List<ActionModel> _actions = [];
  ActionModel? _selectedAction;
  ActionKeyPointModel? _selectedKeyPoint;
  Duration _currentPosition = Duration.zero;
  VideoController? _videoController;
  // Video player is loaded only on user request (file is very large)
  bool _videoLoaded = false;
  bool _isEditMode = false;
  // JSON state
  bool _hasUnsavedChanges = false;
  String? _loadedFromPath; // null = default path obok wideo

  // Playlist state
  List<ActionModel> _playlist = [];
  bool _isPlayingPlaylist = false;
  bool _loopPlaylist = false;
  int _currentPlaylistIndex = 0;
  List<ArtifactModel> _availablePlaylists = [];
  ArtifactModel? _currentPlaylistArtifact;

  // Filtrowanie
  List<String> _selectedActionTypes = [];
  List<String> _selectedPlayers = [];
  bool _isolateSelected = false;

  List<ActionModel> get _filteredActions {
    return _actions.where((a) {
      if (_isEditMode && _isolateSelected && _selectedAction != null) {
        if (a.id != _selectedAction!.id) return false;
      }
      if (_selectedActionTypes.isNotEmpty &&
          !_selectedActionTypes.contains(a.type)) {
        return false;
      }
      if (_selectedPlayers.isNotEmpty &&
          !_selectedPlayers.contains(a.playerId)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Pozycja okienek PIP (Player Focus) dla poszczególnych focus ID
  final Map<String, double> _focusPlayerTops = {};
  final Map<String, double> _focusPlayerRights = {};
  final Map<String, double> _focusPlayerWidths = {};

  double _getFocusPlayerTop(String focusId, int index) {
    if (!_focusPlayerTops.containsKey(focusId)) {
      _focusPlayerTops[focusId] = 16.0 + (index * 190.0);
    }
    return _focusPlayerTops[focusId]!;
  }

  double _getFocusPlayerRight(String focusId) {
    if (!_focusPlayerRights.containsKey(focusId)) {
      _focusPlayerRights[focusId] = 16.0;
    }
    return _focusPlayerRights[focusId]!;
  }

  double _getFocusPlayerWidth(String focusId) {
    if (!_focusPlayerWidths.containsKey(focusId)) {
      _focusPlayerWidths[focusId] = 200.0;
    }
    return _focusPlayerWidths[focusId]!;
  }

  bool _isUpdatingFocus = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = widget.analyticsService ?? AnalyticsService();
    // Check existing analysis in background
    Future.microtask(() async {
      await _loadAvailablePlaylists();
      _checkExistingAnalysis();
      if (widget.initialPlaylistPath != null) {
        _loadInitialPlaylist(widget.initialPlaylistPath!);
      }
    });
  }

  Future<void> _loadAvailablePlaylists() async {
    final allPlaylists = ProjectDataService().artifacts
        .where(
          (a) =>
              a.type == ArtifactType.playlist &&
              a.sourceVideoPath == widget.videoPath,
        )
        .toList();
    if (mounted) {
      setState(() {
        _availablePlaylists = allPlaylists;
        if (widget.initialPlaylistPath != null) {
          try {
            _currentPlaylistArtifact = _availablePlaylists.firstWhere(
              (a) => a.filePath == widget.initialPlaylistPath,
            );
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _loadInitialPlaylist(String path) async {
    try {
      final result = await AnalysisFileService.loadPlaylistFromPath(path);
      if (result == null) return;
      if (!mounted) return;
      setState(() {
        _playlist = result;
        _isPlayingPlaylist = false;
        _currentPlaylistIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wczytano playlistę (${result.length} akcji)'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd odczytu playlisty: $e')));
      }
    }
  }

  void _onPositionChanged(Duration pos) {
    _currentPosition = pos;
    if (_isPlayingPlaylist && _playlist.isNotEmpty) {
      if (_currentPlaylistIndex < _playlist.length) {
        final currentAction = _playlist[_currentPlaylistIndex];
        if (pos.inMilliseconds >= currentAction.endMs) {
          // Move to next action
          _currentPlaylistIndex++;
          if (_currentPlaylistIndex < _playlist.length) {
            _videoController?.player.seek(
              Duration(
                milliseconds: _playlist[_currentPlaylistIndex].startMs.round(),
              ),
            );
          } else {
            // End of playlist
            if (_loopPlaylist) {
              _currentPlaylistIndex = 0;
              _videoController?.player.seek(
                Duration(
                  milliseconds: _playlist[_currentPlaylistIndex].startMs
                      .round(),
                ),
              );
            } else {
              _isPlayingPlaylist = false;
              _videoController?.player.pause();
              setState(() {});
            }
          }
        }
      }
    }
  }

  Future<void> _checkExistingAnalysis() async {
    // First try reading the local JSON directly (fast, no network)
    final base = widget.videoPath.substring(
      0,
      widget.videoPath.lastIndexOf('.'),
    );
    final localFile = File('${base}_analysis.json');
    if (localFile.existsSync()) {
      try {
        final contents = await localFile.readAsString();
        final jsonResponse = jsonDecode(contents);
        final actions = (jsonResponse['actions'] as List)
            .map((v) => ActionModel.fromJson(v))
            .toList();
        if (mounted) {
          setState(() {
            _actions = actions;
          });
        }
        return;
      } catch (_) {}
    }
    // Fallback: ask the backend (with timeout)
    try {
      final results = await _analyticsService.getResults(widget.videoPath);
      if (mounted) {
        setState(() {
          _actions = results;
        });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis failed in backend.')),
        );
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

  void _onActionSelected(ActionModel? action) {
    setState(() {
      _selectedAction = action;
      _selectedKeyPoint = null;
    });
    if (action != null && _videoController != null) {
      _videoController!.player.seek(
        Duration(milliseconds: action.startMs.round()),
      );
    }
  }

  Future<void> _handleActionUpdated(ActionModel action, {bool updateBackend = false}) async {
    // Determine if it is a parent action or a sub-action
    int parentIdx = _actions.indexWhere((a) => a.id == action.id);
    ActionModel? parentToUpdate;

    if (parentIdx != -1) {
      // It is a parent action
      setState(() {
        _actions[parentIdx] = action;
        if (_selectedAction?.id == action.id) {
          _selectedAction = action;
        } else if (_selectedAction != null) {
          // If a sub-action of this parent is currently selected, update it to keep the UI in sync
          final subIdx = action.subActions.indexWhere((sub) => sub.id == _selectedAction!.id);
          if (subIdx != -1) {
            _selectedAction = action.subActions[subIdx];
          }
        }
        _hasUnsavedChanges = true;
      });
      parentToUpdate = action;
    } else {
      // It is a sub-action, find its parent
      for (int i = 0; i < _actions.length; i++) {
        final subIdx = _actions[i].subActions.indexWhere((sub) => sub.id == action.id);
        if (subIdx != -1) {
          setState(() {
            _actions[i].subActions[subIdx] = action;
            if (_selectedAction?.id == action.id) {
              _selectedAction = action;
            }
            _hasUnsavedChanges = true;
          });
          parentToUpdate = _actions[i];
          break;
        }
      }
    }

    setState(() {
      _isUpdatingFocus = false;
    });

    if (updateBackend && parentToUpdate != null) {
      try {
        await _analyticsService.updateAction(
          widget.videoPath,
          parentToUpdate,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sync update with server: $e')),
          );
        }
      }
    }
  }

  void _handleKeyPointSelected(ActionKeyPointModel? keyPoint) {
    setState(() {
      _selectedKeyPoint = keyPoint;
    });
    if (keyPoint != null && _videoController != null) {
      _videoController!.player.seek(
        Duration(milliseconds: keyPoint.timeMs.round()),
      );
    }
  }

  Future<void> _handleKeyPointUpdated(ActionKeyPointModel keyPoint, {bool updateBackend = true}) async {
    for (int i = 0; i < _actions.length; i++) {
      final action = _actions[i];
      final kpIdx = action.keyPoints.indexWhere((kp) => kp.id == keyPoint.id);
      if (kpIdx != -1) {
        final updatedKeyPoints = List<ActionKeyPointModel>.from(action.keyPoints);
        updatedKeyPoints[kpIdx] = keyPoint;
        final updatedAction = action.copyWith(keyPoints: updatedKeyPoints);
        await _handleActionUpdated(updatedAction, updateBackend: updateBackend);
        
        if (_selectedKeyPoint?.id == keyPoint.id) {
          setState(() {
            _selectedKeyPoint = keyPoint;
          });
        }
        return;
      }
      
      for (int j = 0; j < action.subActions.length; j++) {
        final sub = action.subActions[j];
        final subKpIdx = sub.keyPoints.indexWhere((kp) => kp.id == keyPoint.id);
        if (subKpIdx != -1) {
          final updatedSubKeyPoints = List<ActionKeyPointModel>.from(sub.keyPoints);
          updatedSubKeyPoints[subKpIdx] = keyPoint;
          final updatedSub = sub.copyWith(keyPoints: updatedSubKeyPoints);
          
          final updatedSubActions = List<ActionModel>.from(action.subActions);
          updatedSubActions[j] = updatedSub;
          
          final updatedAction = action.copyWith(subActions: updatedSubActions);
          await _handleActionUpdated(updatedAction, updateBackend: updateBackend);
          
          if (_selectedKeyPoint?.id == keyPoint.id) {
            setState(() {
              _selectedKeyPoint = keyPoint;
            });
          }
          return;
        }
      }
    }
  }

  void _onActionAdded() {
    setState(() {
      final start = _currentPosition.inMilliseconds.toDouble();
      final end = start + 2000.0; // 2 sekundy domyślnie
      final newAction = ActionModel(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        type: 'BUMP',
        startMs: start,
        endMs: end,
        playerBox: [0.0, 0.0, 0.0, 0.0],
        playerId: 'Unknown',
        confidence: 1.0,
      );
      _actions.add(newAction);
      _selectedAction = newAction;
      _hasUnsavedChanges = true;
    });
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

      final fileName = widget.videoPath.split(Platform.pathSeparator).last;
      final artifact = ArtifactModel(
        type: ArtifactType.video,
        title: '$fileName - Analiza',
        description: 'Zapisana analiza wideo',
        filePath: widget.videoPath,
      );
      await ProjectDataService().createArtifact(artifact);
      if (widget.projectId != null) {
        await ProjectDataService().linkArtifactToProject(
          widget.projectId!,
          artifact.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Analiza zapisana obok wideo i dodana do artefaktów.',
          ),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
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
          content: Text(
            'Zapisano: ${savedPath.split(Platform.pathSeparator).last}',
          ),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd odczytu: $e')));
      }
    }
  }

  // ─── Playlista IO ──────────────────────────────────────────────────────────

  Future<void> _savePlaylist() async {
    try {
      await AnalysisFileService.savePlaylistToDefault(
        videoPath: widget.videoPath,
        playlist: _playlist,
      );

      final path = AnalysisFileService.defaultPlaylistJsonPath(
        widget.videoPath,
      );
      final fileName = path.split(Platform.pathSeparator).last;
      final artifact = ArtifactModel(
        type: ArtifactType.playlist,
        title: fileName,
        description: 'Domyślna playlista',
        filePath: path,
        sourceVideoPath: widget.videoPath,
      );
      await ProjectDataService().createArtifact(artifact);
      if (widget.projectId != null) {
        await ProjectDataService().linkArtifactToProject(
          widget.projectId!,
          artifact.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlista zapisana i dodana do artefaktów.'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd zapisu playlisty: $e')));
      }
    }
  }

  Future<void> _savePlaylistAs() async {
    try {
      final savedPath = await AnalysisFileService.savePlaylistAs(
        videoPath: widget.videoPath,
        playlist: _playlist,
      );
      if (savedPath == null) return;

      final fileName = savedPath.split(Platform.pathSeparator).last;
      final artifact = ArtifactModel(
        type: ArtifactType.playlist,
        title: fileName,
        description: 'Zapisana playlista',
        filePath: savedPath,
        sourceVideoPath: widget.videoPath,
      );
      await ProjectDataService().createArtifact(artifact);
      if (widget.projectId != null) {
        await ProjectDataService().linkArtifactToProject(
          widget.projectId!,
          artifact.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Zapisano playlistę: $fileName i dodano jako artefakt.',
          ),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd zapisu playlisty: $e')));
      }
    }
  }

  Future<void> _loadPlaylist() async {
    try {
      final result = await AnalysisFileService.loadPlaylistFromPicker();
      if (result == null) return;
      if (!mounted) return;
      setState(() {
        _playlist = result;
        _isPlayingPlaylist = false;
        _currentPlaylistIndex = 0;
        _currentPlaylistArtifact =
            null; // Wczytanie z zewnątrz odpina obecny artefakt
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wczytano playlistę (${result.length} akcji)'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd odczytu playlisty: $e')));
      }
    }
  }

  Future<void> _createNewPlaylist(String name) async {
    final base = widget.videoPath.substring(
      0,
      widget.videoPath.lastIndexOf('.'),
    );
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final String newPath = '${base}_playlist_$uniqueId.json';

    try {
      await AnalysisFileService.savePlaylistToPath(newPath, []);
      final artifact = ArtifactModel(
        type: ArtifactType.playlist,
        title: name,
        description: 'Playlista: $name',
        filePath: newPath,
        sourceVideoPath: widget.videoPath,
      );
      await ProjectDataService().createArtifact(artifact);
      if (widget.projectId != null) {
        await ProjectDataService().linkArtifactToProject(
          widget.projectId!,
          artifact.id,
        );
      }

      if (!mounted) return;
      setState(() {
        _availablePlaylists.add(artifact);
        _currentPlaylistArtifact = artifact;
        _playlist = [];
        _isPlayingPlaylist = false;
        _currentPlaylistIndex = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Utworzono playlistę: $name')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  Future<void> _selectPlaylist(String id) async {
    final artifact = _availablePlaylists.firstWhere((a) => a.id == id);
    setState(() {
      _currentPlaylistArtifact = artifact;
    });
    await _loadInitialPlaylist(artifact.filePath);
  }

  // ─── Usunięcie ─────────────────────────────────────────────────────────────

  Future<void> _deleteAnalysis() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text(
          'Usuń analizę',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Czy na pewno chcesz usunąć wszystkie wyniki analizy?\n'
          'Plik JSON zostanie skasowany z dysku.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Anuluj',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Usuń',
              style: TextStyle(color: Colors.redAccent),
            ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd usuwania: $e')));
      }
    }
  }

  // ─── Pomocnicze ─────────────────────────────────────────────────────────────

  Future<bool?> _confirmDiscardChanges() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      title: const Text(
        'Niezapisane zmiany',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Masz niezapisane zmiany. Czy na pewno chcesz je odrzucić?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Odrzuć',
            style: TextStyle(color: Colors.orangeAccent),
          ),
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
            const Text(
              'Video Analytics Dashboard',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
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
          if (_actions.isNotEmpty && _isEditMode) ...[
            // Wskaźnik niezapisanych zmian
            if (_hasUnsavedChanges)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                child: Tooltip(
                  message: 'Niezapisane zmiany',
                  child: Icon(
                    Icons.circle,
                    color: Colors.orangeAccent,
                    size: 10,
                  ),
                ),
              ),
            // Menu zapisu
            PopupMenuButton<String>(
              tooltip: 'Opcje zapisu',
              icon: Icon(
                Icons.save_alt,
                color: _hasUnsavedChanges
                    ? Colors.orangeAccent
                    : Colors.greenAccent,
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
                  child: Row(
                    children: [
                      Icon(Icons.save, color: Colors.greenAccent, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Zapisz obok wideo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'save_as',
                  child: Row(
                    children: [
                      Icon(
                        Icons.save_as,
                        color: Colors.lightBlueAccent,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Zapisz jako...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Usuń analizę',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          // ── Przycisk wczytaj z pliku (zawsze widoczny) ──────────────────
          IconButton(
            icon: const Icon(
              Icons.folder_open,
              color: Colors.amberAccent,
              size: 22,
            ),
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
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatEta(_etaSeconds),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_actions.isEmpty)
            TextButton.icon(
              icon: const Icon(Icons.analytics, color: Colors.purpleAccent),
              label: const Text(
                'Analyze Video',
                style: TextStyle(color: Colors.white),
              ),
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
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _videoLoaded
                                ? VideoPlayerWidget(
                                    videoFile: File(widget.videoPath),
                                    actions: _filteredActions,
                                    selectedAction: _selectedAction,
                                    selectedKeyPoint: _selectedKeyPoint,
                                    playlistActions: _playlist,
                                    isEditMode: _isEditMode,
                                    onPositionChanged: _onPositionChanged,
                                    onControllerReady: (controller) =>
                                        _videoController = controller,
                                    onActionPlaylistToggled: (action) {
                                      setState(() {
                                        if (_playlist.any(
                                          (a) => a.id == action.id,
                                        )) {
                                          _playlist.removeWhere(
                                            (a) => a.id == action.id,
                                          );
                                        } else {
                                          _playlist.add(action);
                                        }
                                      });
                                    },
                                    onActionSelected: _onActionSelected,
                                    onActionUpdated: _handleActionUpdated,
                                    onKeyPointSelected: _handleKeyPointSelected,
                                    onKeyPointUpdated: _handleKeyPointUpdated,
                                    onActionAdded: (action) {
                                      setState(() {
                                        _actions.add(action);
                                        _actions.sort(
                                          (a, b) =>
                                              a.startMs.compareTo(b.startMs),
                                        );
                                      });
                                    },
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.video_file,
                                          color: Colors.white30,
                                          size: 64,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Wideo nie jest załadowane',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Duże pliki wideo ładują się kilkadziesiąt sekund.',
                                          style: TextStyle(
                                            color: Colors.white30,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.play_circle_outline,
                                          ),
                                          label: const Text(
                                            'Załaduj i odtwórz wideo',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.deepPurpleAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed: () => setState(
                                            () => _videoLoaded = true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        // Focus mode picture-in-picture
                        if (_selectedAction != null)
                          ..._selectedAction!.playerFocuses.asMap().entries.map((entry) {
                            final index = entry.key;
                            final focus = entry.value;
                            final focusId = focus.id;
                            final isFocusActive = focusId == _selectedAction!.activeFocusId;
                            
                            final top = _getFocusPlayerTop(focusId, index);
                            final right = _getFocusPlayerRight(focusId);
                            final width = _getFocusPlayerWidth(focusId);

                            return Positioned(
                              top: top,
                              right: right,
                              width: width,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.move,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          _focusPlayerTops[focusId] = top + details.delta.dy;
                                          _focusPlayerRights[focusId] = right - details.delta.dx;
                                        });
                                      },
                                      child: FocusPlayerWidget(
                                        controller: _videoController!,
                                        focus: focus,
                                        isActive: isFocusActive,
                                        mainPosition: _currentPosition,
                                        isUpdatingFocus: _isUpdatingFocus && isFocusActive,
                                        onResetFocus: _isEditMode && isFocusActive
                                            ? () {
                                                // Start updating focus mode instead of resetting action to 0
                                                setState(() {
                                                  _isUpdatingFocus = true;
                                                });
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  // Uchwyt do zmiany rozmiaru (lewy dolny róg)
                                  Positioned(
                                    bottom: -10,
                                    left: -10,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors
                                          .resizeUpRightDownLeft,
                                      child: GestureDetector(
                                        onPanUpdate: (details) {
                                          setState(() {
                                            // delta.dx ujemna => ruch w lewo => szerokość rośnie
                                            _focusPlayerWidths[focusId] =
                                                (width - details.delta.dx)
                                                    .clamp(100.0, 800.0);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isFocusActive ? Colors.purpleAccent : Colors.grey,
                                            shape: BoxShape.circle,
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black54,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.open_in_full,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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
              currentPosition: _currentPosition,
              actions: _actions,
              selectedAction: _selectedAction,
              selectedKeyPoint: _selectedKeyPoint,
              playlist: _playlist,
              isPlayingPlaylist: _isPlayingPlaylist,
              loopPlaylist: _loopPlaylist,
              isEditMode: _isEditMode,
              selectedActionTypes: _selectedActionTypes,
              selectedPlayers: _selectedPlayers,
              onSelectedActionTypesChanged: (v) =>
                  setState(() => _selectedActionTypes = v),
              onSelectedPlayersChanged: (v) =>
                  setState(() => _selectedPlayers = v),
              isolateSelected: _isolateSelected,
              onIsolateSelectedChanged: (v) =>
                  setState(() => _isolateSelected = v),
              onPlaylistChanged: (newPlaylist) =>
                  setState(() => _playlist = newPlaylist),
              onLoopPlaylistChanged: (val) =>
                  setState(() => _loopPlaylist = val),
              onSavePlaylist: _savePlaylist,
              onSavePlaylistAs: _savePlaylistAs,
              onLoadPlaylist: _loadPlaylist,
              onActionAdded: _onActionAdded,
              initialTabIndex: widget.initialPlaylistPath != null ? 1 : 0,
              availablePlaylists: _availablePlaylists,
              currentPlaylistId: _currentPlaylistArtifact?.id,
              onPlaylistSelected: _selectPlaylist,
              onCreateNewPlaylist: _createNewPlaylist,
              onActionDeleted: (action) {
                setState(() {
                  _actions.removeWhere((a) => a.id == action.id);
                  _playlist.removeWhere((a) => a.id == action.id);
                  if (_selectedAction?.id == action.id) {
                    _selectedAction = null;
                  }
                  _hasUnsavedChanges = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Akcja usunięta.')),
                );
              },
              onPlayPlaylistToggle: () {
                if (_playlist.isEmpty) return;
                setState(() {
                  _isPlayingPlaylist = !_isPlayingPlaylist;
                  if (_isPlayingPlaylist) {
                    _currentPlaylistIndex = 0;
                    _videoController?.player.seek(
                      Duration(milliseconds: _playlist[0].startMs.round()),
                    );
                    _videoController?.player.play();
                  } else {
                    _videoController?.player.pause();
                  }
                });
              },
              onEditModeChanged: (val) {
                setState(() => _isEditMode = val);
              },
              onActionSelected: _onActionSelected,
              onActionUpdated: (updatedAction) => _handleActionUpdated(updatedAction, updateBackend: true),
              onKeyPointSelected: _handleKeyPointSelected,
              onKeyPointUpdated: (updatedKeyPoint) => _handleKeyPointUpdated(updatedKeyPoint, updateBackend: true),
            ),
          ),
        ],
      ),
    );
  }
}
