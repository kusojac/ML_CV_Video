import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../models/artifact_model.dart';
import '../../services/project_data_service.dart';
import '../../theme/kinetic_theme.dart';
import '../project_details_screen.dart';

class DashboardView extends StatefulWidget {
  final VoidCallback onBrowseProjectsTap;
  final VoidCallback onBrowsePlaylistsTap;
  final VoidCallback onBrowseStatsTap;
  final VoidCallback onNewSessionTap;

  const DashboardView({
    super.key,
    required this.onBrowseProjectsTap,
    required this.onBrowsePlaylistsTap,
    required this.onBrowseStatsTap,
    required this.onNewSessionTap,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ProjectDataService _dataService = ProjectDataService();
  int _totalActionsCount = 0;
  bool _loadingActions = true;

  @override
  void initState() {
    super.initState();
    _countTotalActions();
  }

  Future<void> _countTotalActions() async {
    int count = 0;
    try {
      final videos = _dataService.artifacts
          .where((a) => a.type == ArtifactType.video)
          .toList();

      for (var video in videos) {
        final path = video.filePath;
        final base = path.substring(0, path.lastIndexOf('.'));
        final analysisFile = File('${base}_analysis.json');
        if (analysisFile.existsSync()) {
          final content = await analysisFile.readAsString();
          final jsonResponse = jsonDecode(content);
          final actions = jsonResponse['actions'] as List?;
          if (actions != null) {
            count += actions.length;
          }
        }
      }
    } catch (e) {
      debugPrint('Błąd zliczania akcji na dashboardzie: $e');
    }

    if (mounted) {
      setState(() {
        _totalActionsCount = count;
        _loadingActions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = _dataService.projects;
    final videos = _dataService.artifacts.where((a) => a.type == ArtifactType.video).toList();
    final playlists = _dataService.artifacts.where((a) => a.type == ArtifactType.playlist).toList();
    final recentProjects = projects.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayRecent = recentProjects.take(4).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek powitalny
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KINETIC ANALYTICS',
                    style: KineticTheme.getMonoFont(
                      color: KineticTheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1 * 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Centrum Analiz',
                    style: KineticTheme.getDisplayFont(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: KineticTheme.onSurface,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onNewSessionTap,
                icon: const Icon(Icons.add_circle_outline, color: KineticTheme.onPrimaryContainer),
                label: const Text('NOWA SESJA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KineticTheme.primary,
                  foregroundColor: KineticTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Pływające Statystyki (Metrics Grid)
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    title: 'PROJEKTY',
                    value: projects.length.toString(),
                    icon: Icons.folder_copy_rounded,
                    accentColor: KineticTheme.primary,
                    onTap: widget.onBrowseProjectsTap,
                  ),
                  _buildStatCard(
                    title: 'ANALIZOWANE WIDEO',
                    value: videos.length.toString(),
                    icon: Icons.video_camera_back_rounded,
                    accentColor: KineticTheme.secondary,
                    onTap: widget.onBrowseProjectsTap,
                  ),
                  _buildStatCard(
                    title: 'UTWORZONE PLAYLISTY',
                    value: playlists.length.toString(),
                    icon: Icons.playlist_play_rounded,
                    accentColor: const Color(0xFF00C853),
                    onTap: widget.onBrowsePlaylistsTap,
                  ),
                  _buildStatCard(
                    title: 'OZNACZONE ZDARZENIA',
                    value: _loadingActions ? '...' : _totalActionsCount.toString(),
                    icon: Icons.bolt_rounded,
                    accentColor: KineticTheme.tertiary,
                    onTap: widget.onBrowseStatsTap,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),

          // 2 Kolumny: Ostatnie projekty | Szybkie skróty
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ostatnie projekty (70% jeśli szeroki)
                  Expanded(
                    flex: isWide ? 7 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ostatnio modyfikowane projekty',
                          style: KineticTheme.getDisplayFont(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: KineticTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        displayRecent.isEmpty
                            ? _buildEmptyRecentCard()
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayRecent.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final proj = displayRecent[index];
                                  return _buildRecentProjectRow(proj);
                                },
                              ),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 32),
                  // Szybkie Akcje / Skróty
                  if (isWide)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Szybkie akcje',
                            style: KineticTheme.getDisplayFont(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: KineticTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActionButton(
                            label: 'Otwórz bazę projektów',
                            icon: Icons.arrow_forward_rounded,
                            onTap: widget.onBrowseProjectsTap,
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionButton(
                            label: 'Pokaż statystyki zespołów',
                            icon: Icons.analytics_rounded,
                            onTap: widget.onBrowseStatsTap,
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionButton(
                            label: 'Zarządzaj playlistami',
                            icon: Icons.playlist_add_check_rounded,
                            onTap: widget.onBrowsePlaylistsTap,
                          ),
                          const SizedBox(height: 24),
                          // Wskazówka dnia / Pomoc
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: KineticTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: KineticTheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded, color: KineticTheme.secondary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Porada analityczna',
                                      style: KineticTheme.getDisplayFont(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: KineticTheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Podwójne kliknięcie na węzeł projektu w widoku grafu przeniesie Cię bezpośrednio do szczegółów projektu. Używaj skrótu [Spacja], aby szybko zatrzymać odtwarzanie filmu.',
                                  style: KineticTheme.getDisplayFont(
                                    fontSize: 12,
                                    color: KineticTheme.onSurfaceVariant,
                                    lineHeight: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: KineticTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KineticTheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: KineticTheme.getMonoFont(
                        color: KineticTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.05 * 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: KineticTheme.getMonoFont(
                        color: KineticTheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecentCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: KineticTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KineticTheme.outlineVariant, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, color: KineticTheme.onSurfaceVariant.withAlpha(100), size: 48),
            const SizedBox(height: 12),
            Text(
              'Brak projektów w systemie',
              style: KineticTheme.getDisplayFont(color: KineticTheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onNewSessionTap,
              child: const Text('DODAJ PIERWSZY PROJEKT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjectRow(ProjectModel project) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsScreen(project: project),
            ),
          ).then((_) => _countTotalActions()); // odśwież statystyki
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KineticTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KineticTheme.outlineVariant),
          ),
          child: Row(
            children: [
              // Miniaturka lub ikona
              Container(
                width: 64,
                height: 48,
                decoration: BoxDecoration(
                  color: KineticTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: KineticTheme.outlineVariant),
                ),
                child: project.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.network(
                          project.imagePath!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.folder_special, color: KineticTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              // Informacje
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: KineticTheme.getDisplayFont(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KineticTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.description.isNotEmpty ? project.description : 'Brak opisu.',
                      style: KineticTheme.getDisplayFont(
                        fontSize: 12,
                        color: KineticTheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Licznik artefaktów i tagi
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KineticTheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${project.artifactIds.length} artefaktów',
                      style: KineticTheme.getMonoFont(
                        color: KineticTheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${project.createdAt.day.toString().padLeft(2, '0')}.${project.createdAt.month.toString().padLeft(2, '0')}.${project.createdAt.year}',
                    style: KineticTheme.getMonoFont(
                      fontSize: 10,
                      color: KineticTheme.onSurfaceVariant.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        side: const BorderSide(color: KineticTheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: KineticTheme.surfaceContainerLow,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: KineticTheme.getMonoFont(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: KineticTheme.onSurface,
            ),
          ),
          Icon(icon, color: KineticTheme.secondary, size: 18),
        ],
      ),
    );
  }
}
