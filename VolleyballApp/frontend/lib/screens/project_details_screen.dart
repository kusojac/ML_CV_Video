import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/project_model.dart';
import '../models/artifact_model.dart';
import '../services/project_data_service.dart';
import 'video_analysis_screen.dart';

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
      if (query.isEmpty) {
        _filteredArtifacts = List.from(_projectArtifacts);
      } else {
        _filteredArtifacts = _projectArtifacts.where((a) {
          final titleMatch = a.title.toLowerCase().contains(query);
          final tagMatch = a.tags.any((tag) => tag.toLowerCase().contains(query));
          final descMatch = a.description.toLowerCase().contains(query);
          return titleMatch || tagMatch || descMatch;
        }).toList();
      }
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
          // Pasek filtrowania artefaktów
          Padding(
            padding: const EdgeInsets.all(16.0),
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
          // Siatka artefaktów
          Expanded(
            child: _filteredArtifacts.isEmpty
                ? const Center(child: Text('Brak powiązanych artefaktów.'))
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: const Color(0xFF25252D),
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
                    color: Colors.black26,
                    child: artifact.thumbnailPath != null
                        ? Image.file(File(artifact.thumbnailPath!), fit: BoxFit.cover)
                        : Icon(_getIconForArtifact(artifact.type), size: 48, color: _getColorForArtifact(artifact.type).withValues(alpha: 0.5)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getColorForArtifact(artifact.type),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        artifact.type.name.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'unlink') {
                          _unlinkArtifact(artifact);
                        }
                      },
                      itemBuilder: (context) => [
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        artifact.description,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
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
