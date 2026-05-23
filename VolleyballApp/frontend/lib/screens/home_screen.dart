import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_data_service.dart';
import '../theme/kinetic_theme.dart';
import '../widgets/graph_view.dart';
import 'project_details_screen.dart';
import 'sub_views/dashboard_view.dart';
import 'sub_views/playlists_view.dart';
import 'sub_views/team_stats_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectDataService _dataService = ProjectDataService();
  final TextEditingController _searchController = TextEditingController();
  List<ProjectModel> _filteredProjects = [];
  final String _sortOption = 'date_desc';
  final List<String> _selectedFilterTags = [];
  bool _isGraphView = false;
  
  // Stan nawigacji bocznej
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterProjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _dataService.init();
    _filterProjects();
  }

  void _filterProjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<ProjectModel> filtered;
      if (query.isEmpty) {
        filtered = _dataService.projects.toList();
      } else {
        filtered = _dataService.projects.where((project) {
          final nameMatch = project.name.toLowerCase().contains(query);
          final descMatch = project.description.toLowerCase().contains(query);
          final tagMatch = project.tags.any(
            (tag) => tag.toLowerCase().contains(query),
          );
          return nameMatch || descMatch || tagMatch;
        }).toList();
      }

      if (_selectedFilterTags.isNotEmpty) {
        filtered = filtered.where((project) {
          return project.tags.any((t) => _selectedFilterTags.contains(t));
        }).toList();
      }

      if (_sortOption == 'name_asc') {
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      } else if (_sortOption == 'name_desc') {
        filtered.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      } else if (_sortOption == 'date_asc') {
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else if (_sortOption == 'date_desc') {
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _filteredProjects = filtered;
    });
  }

  Future<void> _showAddProjectDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final tagsController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nowy Projekt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa projektu',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Krótki opis'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tagi (oddzielone przecinkami)',
                    hintText: 'np. JanKowalski, trening, przyjęcie',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Utwórz'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final tags = tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newProject = ProjectModel(
        name: nameController.text.trim(),
        description: descController.text.trim(),
        tags: tags,
      );

      await _dataService.createProject(newProject);
      _filterProjects();
      
      // Po utworzeniu, przejdź do widoku projektów (tab 1)
      setState(() {
        _currentTab = 1;
      });
    }
  }

  Future<void> _editProjectDialog(ProjectModel project) async {
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description);
    final tagsController = TextEditingController(text: project.tags.join(', '));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edytuj Projekt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa projektu',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Krótki opis'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tagi (oddzielone przecinkami)',
                    hintText: 'np. JanKowalski, trening, przyjęcie',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final tags = tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      setState(() {
        project.name = nameController.text.trim();
        project.description = descController.text.trim();
        project.tags = tags;
      });

      await _dataService.updateProject(project);
      _filterProjects();
    }
  }

  Future<void> _deleteProject(ProjectModel project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń projekt'),
        content: Text(
          'Czy na pewno chcesz usunąć projekt "${project.name}"?\nArtefakty wciąż pozostaną w bazie globalnej.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KineticTheme.tertiary, foregroundColor: KineticTheme.onTertiary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dataService.deleteProject(project.id);
      _filterProjects();
    }
  }

  Widget _viewToggleBtn({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? KineticTheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? Colors.transparent : KineticTheme.outline),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? KineticTheme.onPrimaryContainer : KineticTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Pasek Boczny Nawigacji (Sidebar) ──
          _buildSidebar(),

          // ── Główny Obszar Treści ──
          Expanded(
            child: Container(
              color: KineticTheme.background,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  DashboardView(
                    onBrowseProjectsTap: () => setState(() => _currentTab = 1),
                    onBrowsePlaylistsTap: () => setState(() => _currentTab = 2),
                    onBrowseStatsTap: () => setState(() => _currentTab = 3),
                    onNewSessionTap: _showAddProjectDialog,
                  ),
                  _buildProjectsScreen(),
                  const PlaylistsView(),
                  const TeamStatsView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: KineticTheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: KineticTheme.outlineVariant, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kinetic',
                  style: KineticTheme.getDisplayFont(
                    color: KineticTheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'ANALYTICS',
                  style: KineticTheme.getMonoFont(
                    color: KineticTheme.onSurfaceVariant.withAlpha(180),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.15 * 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Elementy menu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSidebarMenuItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarMenuItem(
                    index: 1,
                    icon: Icons.video_camera_back_rounded,
                    label: 'Baza Projektów',
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarMenuItem(
                    index: 2,
                    icon: Icons.playlist_play_rounded,
                    label: 'Playlisty wideo',
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarMenuItem(
                    index: 3,
                    icon: Icons.analytics_rounded,
                    label: 'Statystyki zespołów',
                  ),
                ],
              ),
            ),
          ),

          // Przycisk Nowa Sesja i Ustawienia na dole
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddProjectDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('NOWA SESJA'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: KineticTheme.primaryContainer,
                    foregroundColor: KineticTheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: KineticTheme.outlineVariant, height: 1),
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.settings_rounded, color: KineticTheme.onSurfaceVariant),
                  title: Text(
                    'Ustawienia',
                    style: KineticTheme.getDisplayFont(
                      color: KineticTheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wersja Kinetic Analytics v1.0.0')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenuItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? KineticTheme.primaryContainer.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? KineticTheme.primary.withAlpha(50) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? KineticTheme.primary : KineticTheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: KineticTheme.getDisplayFont(
                color: isSelected ? KineticTheme.primary : KineticTheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsScreen() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pasek górny bazy projektów
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Baza projektów',
                    style: KineticTheme.getDisplayFont(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: KineticTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Zarządzaj sesjami analizy wideo i śledź powiązane z nimi artefakty.',
                    style: KineticTheme.getDisplayFont(
                      fontSize: 16,
                      color: KineticTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _viewToggleBtn(
                    icon: Icons.grid_view_rounded,
                    tooltip: 'Widok kafelków',
                    active: !_isGraphView,
                    onTap: () => setState(() => _isGraphView = false),
                  ),
                  const SizedBox(width: 10),
                  _viewToggleBtn(
                    icon: Icons.account_tree_outlined,
                    tooltip: 'Widok grafu powiązań',
                    active: _isGraphView,
                    onTap: () => setState(() => _isGraphView = true),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filtr wyszukiwania
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Filtruj po nazwie, opisie lub tagach...',
                    prefixIcon: Icon(Icons.search_rounded, color: KineticTheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Siatka lub graf
          Expanded(
            child: _isGraphView
                ? GraphView(
                    projects: _filteredProjects,
                    onRefresh: _loadData,
                    onProjectTap: (project) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailsScreen(project: project),
                        ),
                      ).then((_) => _filterProjects());
                    },
                    onProjectEdit: _editProjectDialog,
                    onProjectDelete: _deleteProject,
                  )
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 64,
                              color: KineticTheme.onSurfaceVariant.withAlpha(60),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Brak projektów spełniających kryteria.',
                              style: TextStyle(color: KineticTheme.onSurfaceVariant, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddProjectDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('NOWY PROJEKT'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = _filteredProjects[index];
                          return _buildProjectTile(project);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectTile(ProjectModel project) {
    final dateStr = '${project.createdAt.day.toString().padLeft(2, '0')}.${project.createdAt.month.toString().padLeft(2, '0')}.${project.createdAt.year}';
    return Card(
      color: KineticTheme.surfaceContainerLow,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsScreen(project: project),
            ),
          ).then((_) => _filterProjects());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: KineticTheme.surfaceContainer,
                    child: project.imagePath != null
                        ? Image.network(
                            project.imagePath!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.folder_open_rounded,
                            size: 64,
                            color: KineticTheme.primary,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: KineticTheme.background.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: KineticTheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: KineticTheme.secondary, size: 16),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Edytuj projekt',
                            onPressed: () => _editProjectDialog(project),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: KineticTheme.tertiary, size: 16),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Usuń projekt',
                            onPressed: () => _deleteProject(project),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: KineticTheme.getDisplayFont(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KineticTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: KineticTheme.getMonoFont(
                        fontSize: 10,
                        color: KineticTheme.onSurfaceVariant.withAlpha(120),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        project.description.isNotEmpty ? project.description : 'Brak opisu.',
                        style: KineticTheme.getDisplayFont(
                          fontSize: 13,
                          color: KineticTheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (project.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: project.tags.map((tag) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: KineticTheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: KineticTheme.outlineVariant),
                              ),
                              child: Text(
                                tag,
                                style: KineticTheme.getDisplayFont(fontSize: 10, color: KineticTheme.onSurface),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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
