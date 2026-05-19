import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_data_service.dart';
import 'project_details_screen.dart';
import '../widgets/graph_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectDataService _dataService = ProjectDataService();
  final TextEditingController _searchController = TextEditingController();
  List<ProjectModel> _filteredProjects = [];
  String _sortOption = 'date_desc';
  final List<String> _selectedFilterTags = [];
  bool _isGraphView = false;

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
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else if (_sortOption == 'name_desc') {
        filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
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
    final tagsController = TextEditingController(); // przecinki dla tagów

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
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Krótki opis'),
                  maxLines: 3,
                ),
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
                  decoration: const InputDecoration(labelText: 'Nazwa projektu'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Krótki opis'),
                  maxLines: 3,
                ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń', style: TextStyle(color: Colors.white)),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.deepPurpleAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zbiór Projektów'),
        actions: [
          // Toggle widok: kafelki / graf
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _viewToggleBtn(
                  icon: Icons.grid_view,
                  tooltip: 'Widok kafelek',
                  active: !_isGraphView,
                  onTap: () => setState(() => _isGraphView = false),
                ),
                _viewToggleBtn(
                  icon: Icons.account_tree,
                  tooltip: 'Widok grafowy',
                  active: _isGraphView,
                  onTap: () => setState(() => _isGraphView = true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nowy Projekt',
            onPressed: _showAddProjectDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Wyszukaj i sortuj'),
              leading: Icon(
                Icons.tune,
                color: (_selectedFilterTags.isNotEmpty || _searchController.text.isNotEmpty)
                    ? Colors.purpleAccent
                    : null,
              ),
              subtitle: Builder(builder: (context) {
                final parts = <String>[];
                if (_searchController.text.isNotEmpty) parts.add('"${_searchController.text}"');
                for (final t in _selectedFilterTags) { parts.add('#$t'); }
                if (parts.isEmpty) return const SizedBox.shrink();
                return Text(
                  parts.join(' · '),
                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
              trailing: _selectedFilterTags.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purpleAccent),
                          ),
                          child: Text(
                            '${_selectedFilterTags.length}',
                            style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    )
                  : null,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Filtruj po nazwie, opisie lub tagach...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortOption,
                          icon: const Icon(Icons.sort, color: Colors.white70),
                          dropdownColor: const Color(0xFF2E2E2E),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'date_desc', child: Text('Najnowsze')),
                            DropdownMenuItem(value: 'date_asc', child: Text('Najstarsze')),
                            DropdownMenuItem(value: 'name_asc', child: Text('Nazwa (A-Z)')),
                            DropdownMenuItem(value: 'name_desc', child: Text('Nazwa (Z-A)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortOption = val;
                                _filterProjects();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text('Dodaj filtr tagu...', style: TextStyle(color: Colors.white70)),
                          dropdownColor: const Color(0xFF2E2E2E),
                          style: const TextStyle(color: Colors.white),
                          value: null,
                          icon: const Icon(Icons.sell, color: Colors.white70, size: 20),
                          items: _dataService.projects
                              .expand((p) => p.tags)
                              .toSet()
                              .where((tag) => !_selectedFilterTags.contains(tag))
                              .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedFilterTags.add(val);
                                _filterProjects();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedFilterTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _selectedFilterTags.map((tag) {
                          return InputChip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.purple.withValues(alpha: 0.3),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedFilterTags.remove(tag);
                                _filterProjects();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isGraphView
                ? GraphView(
                    projects: _filteredProjects,
                    onRefresh: _filterProjects,
                    onProjectTap: (project) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailsScreen(project: project),
                        ),
                      ).then((_) => _filterProjects());
                    },
                    onProjectEdit: (project) => _editProjectDialog(project),
                    onProjectDelete: (project) => _deleteProject(project),
                  )
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.white30,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Brak projektów',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Dodaj nowy projekt, aby rozpocząć pracę.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
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
    return Card(
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
            // Placeholder dla grafiki (miniaturki)
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: project.imagePath != null
                        ? Image.network(
                            project.imagePath!,
                            fit: BoxFit.cover,
                          ) // W przyszłości np. File(imagePath)
                        : const Icon(
                            Icons.folder_special,
                            size: 72,
                            color: Colors.white24,
                          ),
                  ),
                  // Mroczny gradient od dołu, aby tekst/ikony były czytelne
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                tooltip: 'Edytuj projekt',
                                onPressed: () => _editProjectDialog(project),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                tooltip: 'Usuń projekt',
                                onPressed: () => _deleteProject(project),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Detale projektu
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        project.description.isNotEmpty
                            ? project.description
                            : 'Brak opisu.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (project.tags.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 6,
                          children: project.tags.map((tag) {
                            return Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
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
