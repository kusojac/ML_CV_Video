import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/project_model.dart';
import '../models/artifact_model.dart';
import '../services/project_data_service.dart';
import 'video_analysis_screen.dart';
import 'artifact_edit_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final ProjectDataService _dataService = ProjectDataService();
  final TextEditingController _searchController = TextEditingController();
  List<ArtifactModel> _projectArtifacts = [];
  List<ArtifactModel> _filteredArtifacts = [];
  String _sortOption = 'date_desc';
  
  final List<ArtifactType> _selectedTypes = [];
  final List<String> _selectedCategories = [];
  final List<String> _selectedTags = [];
  final List<String> _selectedTeams = [];

  @override
  void initState() {
    super.initState();
    _loadArtifacts();
    _searchController.addListener(_filterArtifacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadArtifacts() {
    // Odśwież dane z serwisu (w razie gdyby zostały zaktualizowane w innej stronie)
    setState(() {
      _projectArtifacts = widget.project.artifactIds
          .map((id) => _dataService.getArtifactById(id))
          .where((a) => a != null)
          .cast<ArtifactModel>()
          .toList();
      _filterArtifacts();
    });
  }

  void _filterArtifacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<ArtifactModel> filtered;
      if (query.isEmpty) {
        filtered = List.from(_projectArtifacts);
      } else {
        filtered = _projectArtifacts.where((a) {
          final titleMatch = a.title.toLowerCase().contains(query);
          final tagMatch = a.tags.any((tag) => tag.toLowerCase().contains(query));
          final descMatch = a.description.toLowerCase().contains(query);
          return titleMatch || tagMatch || descMatch;
        }).toList();
      }

      if (_selectedTypes.isNotEmpty) {
        filtered = filtered.where((a) => _selectedTypes.contains(a.type)).toList();
      }
      if (_selectedCategories.isNotEmpty) {
        filtered = filtered.where((a) => a.videoCategory != null && _selectedCategories.contains(a.videoCategory!)).toList();
      }
      if (_selectedTags.isNotEmpty) {
        filtered = filtered.where((a) => a.tags.any((t) => _selectedTags.contains(t))).toList();
      }
      if (_selectedTeams.isNotEmpty) {
        filtered = filtered.where((a) => (a.teamA != null && _selectedTeams.contains(a.teamA!.name)) || (a.teamB != null && _selectedTeams.contains(a.teamB!.name))).toList();
      }

      if (_sortOption == 'title_asc') {
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      } else if (_sortOption == 'title_desc') {
        filtered.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      } else if (_sortOption == 'date_asc') {
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else if (_sortOption == 'date_desc') {
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else if (_sortOption == 'type') {
        filtered.sort((a, b) {
          final typeComp = a.type.index.compareTo(b.type.index);
          if (typeComp != 0) return typeComp;
          return b.createdAt.compareTo(a.createdAt);
        });
      } else if (_sortOption == 'category') {
        filtered.sort((a, b) {
          final catA = a.videoCategory ?? 'Z'; // by default put nulls at the end
          final catB = b.videoCategory ?? 'Z';
          final comp = catA.compareTo(catB);
          if (comp != 0) return comp;
          return b.createdAt.compareTo(a.createdAt);
        });
      } else if (_sortOption == 'team') {
        filtered.sort((a, b) {
          final teamA = a.teamA?.name ?? 'Z';
          final teamB = b.teamA?.name ?? 'Z';
          final comp = teamA.compareTo(teamB);
          if (comp != 0) return comp;
          return b.createdAt.compareTo(a.createdAt);
        });
      }

      _filteredArtifacts = filtered;
    });
  }

  Future<void> _importVideoArtifact() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      final fileName = path.split(Platform.pathSeparator).last;

      final newArtifact = ArtifactModel(
        type: ArtifactType.video,
        title: fileName,
        description: 'Importowane wideo',
        filePath: path,
        tags: ['wideo'],
      );

      await _dataService.createArtifact(newArtifact);
      await _dataService.linkArtifactToProject(widget.project.id, newArtifact.id);
      
      _loadArtifacts();
    }
  }

  // Otwarcie dialogu z listą WSZYSTKICH artefaktów w bazie, aby dodać je do obecnego projektu
  Future<void> _linkExistingArtifactDialog() async {
    final allArtifacts = _dataService.artifacts;
    final unlinkedArtifacts = allArtifacts.where((a) => !widget.project.artifactIds.contains(a.id)).toList();

    if (unlinkedArtifacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak innych artefaktów do podpięcia.')),
      );
      return;
    }

    final selected = await showDialog<ArtifactModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Podepnij istniejący artefakt'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: unlinkedArtifacts.length,
              itemBuilder: (context, index) {
                final a = unlinkedArtifacts[index];
                return ListTile(
                  leading: Icon(_getIconForArtifact(a.type)),
                  title: Text(a.title),
                  subtitle: Text(a.type.name),
                  onTap: () => Navigator.pop(context, a),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await _dataService.linkArtifactToProject(widget.project.id, selected.id);
      _loadArtifacts();
    }
  }

  IconData _getIconForArtifact(ArtifactType type) {
    switch (type) {
      case ArtifactType.video:
        return Icons.videocam;
      case ArtifactType.playlist:
        return Icons.playlist_play;
      case ArtifactType.action:
        return Icons.flash_on;
    }
  }

  Color _getColorForArtifact(ArtifactType type) {
    switch (type) {
      case ArtifactType.video:
        return Colors.blueAccent;
      case ArtifactType.playlist:
        return Colors.greenAccent;
      case ArtifactType.action:
        return Colors.orangeAccent;
    }
  }

  Future<void> _unlinkArtifact(ArtifactModel artifact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odłącz artefakt'),
        content: Text('Czy na pewno chcesz odłączyć artefakt "${artifact.title}" od tego projektu?\nNie zostanie on usunięty z dysku.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Odłącz', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dataService.unlinkArtifactFromProject(widget.project.id, artifact.id);
      _loadArtifacts();
    }
  }

  Future<void> _editArtifact(ArtifactModel artifact) async {
    final updatedArtifact = await Navigator.push<ArtifactModel?>(
      context,
      MaterialPageRoute(
        builder: (context) => ArtifactEditScreen(artifact: artifact),
      ),
    );

    if (updatedArtifact != null) {
      _loadArtifacts(); // Odśwież widok po powrocie
    }
  }

  Future<void> _editProjectDetailsDialog() async {
    final nameController = TextEditingController(text: widget.project.name);
    final descController = TextEditingController(text: widget.project.description);
    final tagsController = TextEditingController(text: widget.project.tags.join(', '));

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
        widget.project.name = nameController.text.trim();
        widget.project.description = descController.text.trim();
        widget.project.tags = tags;
      });

      await _dataService.updateProject(widget.project);
    }
  }

  void _openArtifact(ArtifactModel artifact) {
    // W zależności od typu, otwieramy ekran z odpowiednim widokiem
    // Obecnie zakładamy, że VideoAnalysisScreen obsługuje główny wideo
    // Dla playlist / akcji powinniśmy przekazać context
    String videoToOpen = artifact.filePath;
    String? playlistToOpen;

    if (artifact.type == ArtifactType.playlist || artifact.type == ArtifactType.action) {
      if (artifact.sourceVideoPath != null && artifact.sourceVideoPath!.isNotEmpty) {
         videoToOpen = artifact.sourceVideoPath!;
      }
      if (artifact.type == ArtifactType.playlist) {
        playlistToOpen = artifact.filePath;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoAnalysisScreen(
          videoPath: videoToOpen,
          projectId: widget.project.id,
          initialPlaylistPath: playlistToOpen,
        ),
      ),
    ).then((_) => _loadArtifacts());
  }

  Widget _buildFilterDropdown<T>(String label, Set<T> allItems, List<T> selectedItems, ValueChanged<T> onSelected, String Function(T) labelBuilder) {
    final available = allItems.where((item) => !selectedItems.contains(item)).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          hint: Text('Filtruj: $label', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          dropdownColor: const Color(0xFF2E2E2E),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          value: null,
          icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 16),
          items: available.map((item) => DropdownMenuItem(value: item, child: Text(labelBuilder(item)))).toList(),
          onChanged: (val) {
            if (val != null) onSelected(val);
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.purple.withValues(alpha: 0.3),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProjectDetailsDialog,
            tooltip: 'Edytuj projekt',
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _linkExistingArtifactDialog,
            tooltip: 'Podepnij istniejący artefakt',
          ),
          IconButton(
            icon: const Icon(Icons.add_to_drive),
            onPressed: _importVideoArtifact,
            tooltip: 'Importuj nowe wideo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Informacje o projekcie
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: const Color(0xFF1E1E24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.project.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                if (widget.project.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: widget.project.tags.map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.purple.withValues(alpha: 0.3),
                    )).toList(),
                  ),
              ],
            ),
          ),
          // Pasek filtrowania i sortowania artefaktów
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Wyszukaj i sortuj artefakty'),
              leading: Icon(
                Icons.filter_list,
                color: (_selectedTypes.isNotEmpty || _selectedCategories.isNotEmpty || _selectedTags.isNotEmpty || _selectedTeams.isNotEmpty || _searchController.text.isNotEmpty)
                    ? Colors.purpleAccent
                    : null,
              ),
              subtitle: Builder(builder: (context) {
                final parts = <String>[];
                if (_searchController.text.isNotEmpty) parts.add('"${_searchController.text}"');
                for (final t in _selectedTypes) { parts.add('Typ: ${t.name}'); }
                for (final c in _selectedCategories) { parts.add(c); }
                for (final t in _selectedTags) { parts.add('#$t'); }
                for (final team in _selectedTeams) { parts.add(team); }
                if (parts.isEmpty) return const SizedBox.shrink();
                return Text(
                  parts.join(' · '),
                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
              trailing: () {
                final count = _selectedTypes.length + _selectedCategories.length + _selectedTags.length + _selectedTeams.length;
                if (count == 0) return null;
                return Row(
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
                        '$count',
                        style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                );
              }(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Filtruj artefakty...',
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
                            DropdownMenuItem(value: 'title_asc', child: Text('Nazwa (A-Z)')),
                            DropdownMenuItem(value: 'title_desc', child: Text('Nazwa (Z-A)')),
                            DropdownMenuItem(value: 'type', child: Text('Typ artefaktu')),
                            DropdownMenuItem(value: 'category', child: Text('Kategoria')),
                            DropdownMenuItem(value: 'team', child: Text('Drużyna')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortOption = val;
                                _filterArtifacts();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterDropdown<ArtifactType>('Typ', _projectArtifacts.map((a) => a.type).toSet(), _selectedTypes, (val) {
                        setState(() { _selectedTypes.add(val); _filterArtifacts(); });
                      }, (type) => type.name),
                      const SizedBox(width: 8),
                      _buildFilterDropdown<String>('Kategoria', _projectArtifacts.map((a) => a.videoCategory).whereType<String>().toSet(), _selectedCategories, (val) {
                        setState(() { _selectedCategories.add(val); _filterArtifacts(); });
                      }, (str) => str),
                      const SizedBox(width: 8),
                      _buildFilterDropdown<String>('Tagi', _projectArtifacts.expand((a) => a.tags).toSet(), _selectedTags, (val) {
                        setState(() { _selectedTags.add(val); _filterArtifacts(); });
                      }, (str) => str),
                      const SizedBox(width: 8),
                      _buildFilterDropdown<String>('Drużyna', _projectArtifacts.expand((a) => [a.teamA?.name, a.teamB?.name]).whereType<String>().toSet(), _selectedTeams, (val) {
                        setState(() { _selectedTeams.add(val); _filterArtifacts(); });
                      }, (str) => str),
                    ],
                  ),
                ),
                if (_selectedTypes.isNotEmpty || _selectedCategories.isNotEmpty || _selectedTags.isNotEmpty || _selectedTeams.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          ..._selectedTypes.map((t) => _buildFilterChip('Typ: ${t.name}', () {
                            setState(() { _selectedTypes.remove(t); _filterArtifacts(); });
                          })),
                          ..._selectedCategories.map((c) => _buildFilterChip('Kat: $c', () {
                            setState(() { _selectedCategories.remove(c); _filterArtifacts(); });
                          })),
                          ..._selectedTags.map((t) => _buildFilterChip('Tag: $t', () {
                            setState(() { _selectedTags.remove(t); _filterArtifacts(); });
                          })),
                          ..._selectedTeams.map((team) => _buildFilterChip('Drużyna: $team', () {
                            setState(() { _selectedTeams.remove(team); _filterArtifacts(); });
                          })),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Siatka artefaktów
          Expanded(
            child: _filteredArtifacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off, size: 64, color: Colors.white30),
                        const SizedBox(height: 16),
                        const Text(
                          'Brak powiązanych artefaktów',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Podepnij lub zaimportuj artefakt, aby go przeanalizować.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredArtifacts.length,
                    itemBuilder: (context, index) {
                      final artifact = _filteredArtifacts[index];
                      return _buildArtifactTile(artifact);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtifactTile(ArtifactModel artifact) {
    return Card(
      child: InkWell(
        onTap: () => _openArtifact(artifact),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Obszar grafiki
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
                    child: artifact.thumbnailPath != null
                        ? Image.file(File(artifact.thumbnailPath!), fit: BoxFit.cover)
                        : Icon(_getIconForArtifact(artifact.type), size: 48, color: _getColorForArtifact(artifact.type).withValues(alpha: 0.5)),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorForArtifact(artifact.type),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Text(
                            artifact.type.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                        if (artifact.videoCategory != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: artifact.videoCategory == 'Mecz' ? Colors.redAccent : Colors.teal,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Text(
                              artifact.videoCategory!.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      tooltip: 'Opcje artefaktu',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editArtifact(artifact);
                        } else if (value == 'unlink') {
                          _unlinkArtifact(artifact);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edytuj szczegóły'),
                        ),
                        const PopupMenuItem(
                          value: 'unlink',
                          child: Text('Odłącz od projektu'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Detale artefaktu
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        artifact.description,
                        style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
