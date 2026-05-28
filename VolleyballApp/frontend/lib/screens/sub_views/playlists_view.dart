import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/artifact_model.dart';
import '../../services/project_data_service.dart';
import '../../theme/kinetic_theme.dart';
import '../video_analysis_screen.dart';

class PlaylistsView extends StatefulWidget {
  final VoidCallback? onGoToProjectsTap;
  const PlaylistsView({super.key, this.onGoToProjectsTap});

  @override
  State<PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<PlaylistsView> {
  final ProjectDataService _dataService = ProjectDataService();
  final Map<String, int> _playlistClipsCount = {};
  bool _loadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylistDetails();
  }

  Future<void> _loadPlaylistDetails() async {
    final playlists = _dataService.artifacts
        .where((a) => a.type == ArtifactType.playlist)
        .toList();

    for (var playlist in playlists) {
      try {
        final file = File(playlist.filePath);
        if (file.existsSync()) {
          final content = await file.readAsString();
          final list = jsonDecode(content) as List?;
          if (list != null) {
            _playlistClipsCount[playlist.id] = list.length;
          }
        }
      } catch (e) {
        debugPrint('Błąd wczytywania szczegółów playlisty ${playlist.id}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _loadingCounts = false;
      });
    }
  }

  void _openPlaylist(ArtifactModel playlist) {
    if (playlist.sourceVideoPath == null || playlist.sourceVideoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak powiązanego pliku wideo dla tej playlisty.'),
          backgroundColor: KineticTheme.errorContainer,
        ),
      );
      return;
    }

    final videoFile = File(playlist.sourceVideoPath!);
    if (!videoFile.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nie odnaleziono oryginalnego wideo: ${playlist.sourceVideoPath}',
          ),
          backgroundColor: KineticTheme.errorContainer,
        ),
      );
      return;
    }

    // Znajdź powiązany projekt, by przekazać projectId (jeśli istnieje)
    String? projectId;
    for (var project in _dataService.projects) {
      if (project.artifactIds.contains(playlist.id)) {
        projectId = project.id;
        break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoAnalysisScreen(
          videoPath: playlist.sourceVideoPath!,
          projectId: projectId,
          initialPlaylistPath: playlist.filePath,
        ),
      ),
    ).then((_) => _loadPlaylistDetails());
  }

  Future<void> _deletePlaylist(ArtifactModel playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń playlistę'),
        content: Text(
          'Czy na pewno chcesz usunąć playlistę "${playlist.title}"?\nPlik JSON zostanie trwale usunięty z dysku.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KineticTheme.errorContainer,
              foregroundColor: KineticTheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Usuń plik fizyczny
      try {
        final file = File(playlist.filePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Błąd usuwania pliku playlisty: $e');
      }

      await _dataService.deleteArtifact(playlist.id);
      _loadPlaylistDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlists = _dataService.artifacts
        .where((a) => a.type == ArtifactType.playlist)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Playlisty wideo',
            style: KineticTheme.getDisplayFont(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: KineticTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zarządzaj wybranymi klipami, kolejnością odtwarzania oraz odtwarzaj sekwencje taktyczne.',
            style: KineticTheme.getDisplayFont(
              fontSize: 16,
              color: KineticTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: playlists.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final count = _playlistClipsCount[playlist.id] ?? 0;
                      return _buildPlaylistCard(playlist, count);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_play_rounded,
            color: KineticTheme.onSurfaceVariant.withAlpha(50),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Brak utworzonych playlist',
            style: KineticTheme.getDisplayFont(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: KineticTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Playlisty możesz tworzyć w oknie analizy wideo, przeciągając wybrane akcje na oś czasu.',
            textAlign: TextAlign.center,
            style: KineticTheme.getDisplayFont(
              fontSize: 14,
              color: KineticTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onGoToProjectsTap,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('PRZEJDŹ DO PROJEKTÓW'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(ArtifactModel playlist, int clipsCount) {
    final dateStr =
        '${playlist.createdAt.day.toString().padLeft(2, '0')}.${playlist.createdAt.month.toString().padLeft(2, '0')}.${playlist.createdAt.year}';

    return Card(
      color: KineticTheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    playlist.title,
                    style: KineticTheme.getDisplayFont(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: KineticTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: KineticTheme.tertiary,
                    size: 20,
                  ),
                  tooltip: 'Usuń playlistę',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => _deletePlaylist(playlist),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              playlist.description.isNotEmpty
                  ? playlist.description
                  : 'Brak opisu.',
              style: KineticTheme.getDisplayFont(
                fontSize: 13,
                color: KineticTheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loadingCounts ? 'Klipów: ...' : 'Klipów: $clipsCount',
                      style: KineticTheme.getMonoFont(
                        color: KineticTheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: KineticTheme.getMonoFont(
                        color: KineticTheme.onSurfaceVariant.withAlpha(100),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openPlaylist(playlist),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('ODTWÓRZ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: KineticTheme.getMonoFont(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
