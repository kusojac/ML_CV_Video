import 'package:flutter/material.dart';
import '../models/artifact_model.dart';
import '../models/team_metadata.dart';
import '../theme/kinetic_theme.dart';

class ArtifactEditScreen extends StatefulWidget {
  final ArtifactModel artifact;

  const ArtifactEditScreen({super.key, required this.artifact});

  @override
  State<ArtifactEditScreen> createState() => _ArtifactEditScreenState();
}

class _ArtifactEditScreenState extends State<ArtifactEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;

  String? _videoCategory;
  late TeamMetadata _teamA;
  late TeamMetadata _teamB;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.artifact.title);
    _descController = TextEditingController(text: widget.artifact.description);
    _tagsController = TextEditingController(text: widget.artifact.tags.join(', '));
    
    _videoCategory = widget.artifact.videoCategory;
    
    _teamA = widget.artifact.teamA != null 
        ? TeamMetadata.fromJson(widget.artifact.teamA!.toJson()) 
        : TeamMetadata(name: 'Gospodarze');
        
    _teamB = widget.artifact.teamB != null 
        ? TeamMetadata.fromJson(widget.artifact.teamB!.toJson()) 
        : TeamMetadata(name: 'Goście');

    _titleController.addListener(_markDirty);
    _descController.addListener(_markDirty);
    _tagsController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _save() {
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    widget.artifact.title = _titleController.text.trim();
    widget.artifact.description = _descController.text.trim();
    widget.artifact.tags = tags;
    widget.artifact.videoCategory = _videoCategory;

    if (_videoCategory == 'Mecz') {
      widget.artifact.teamA = _teamA;
      widget.artifact.teamB = _teamB;
    } else if (_videoCategory == 'Trening') {
      widget.artifact.teamA = _teamA;
      widget.artifact.teamB = null;
    } else {
      widget.artifact.teamA = null;
      widget.artifact.teamB = null;
    }

    Navigator.pop(context, widget.artifact);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KineticTheme.surfaceContainerLow,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 36),
        title: const Text('Niezapisane zmiany', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Masz niezapisane zmiany w edytowanych metadanych. Co chcesz zrobić?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Odrzuć zmiany', style: TextStyle(color: Colors.orangeAccent)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Zapisz i wyjdź'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, 'save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      _save();
      return false;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  void _addPlayer(TeamMetadata team) {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController();
        final numCtrl = TextEditingController();
        String position = 'Przyjmujący';

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Dodaj zawodnika'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Imię i nazwisko'),
                ),
                TextField(
                  controller: numCtrl,
                  decoration: const InputDecoration(labelText: 'Numer'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: position,
                  decoration: const InputDecoration(labelText: 'Pozycja'),
                  items: ['Rozgrywający', 'Przyjmujący', 'Atakujący', 'Środkowy', 'Libero']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => position = v);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    setState(() {
                      team.players.add(PlayerMetadata(
                        name: nameCtrl.text.trim(),
                        number: numCtrl.text.trim(),
                        position: position,
                      ));
                      _isDirty = true;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Dodaj'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamSection(TeamMetadata team, String title) {
    return Card(
      color: KineticTheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: team.name,
                    decoration: InputDecoration(labelText: title),
                    onChanged: (v) {
                      team.name = v;
                      _markDirty();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.blueAccent),
                  tooltip: 'Dodaj zawodnika',
                  onPressed: () => _addPlayer(team),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (team.players.isEmpty)
              const Text('Brak zawodników', style: TextStyle(color: Colors.white54)),
            ...team.players.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withValues(alpha: 0.3),
                  child: Text(p.number, style: const TextStyle(fontSize: 12)),
                ),
                title: Text(p.name),
                subtitle: Text(p.position),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                  tooltip: 'Usuń zawodnika',
                  onPressed: () {
                    setState(() {
                      team.players.removeAt(idx);
                      _isDirty = true;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _onWillPop();
        if (canLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edycja szczegółów wideo'),
          actions: [
            if (_isDirty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                child: Tooltip(
                  message: 'Niezapisane zmiany',
                  child: Icon(Icons.circle, color: Colors.orangeAccent, size: 10),
                ),
              ),
            IconButton(
              icon: Icon(
                Icons.save_rounded,
                color: _isDirty ? Colors.orangeAccent : Colors.white38,
              ),
              tooltip: _isDirty ? 'Zapisz zmiany' : 'Brak zmian do zapisu',
              onPressed: _isDirty ? _save : null,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Podstawowe dane
              const Text('Podstawowe informacje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tytuł wideo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Opis', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tagi (oddzielone przecinkami)',
                  border: OutlineInputBorder(),
                  hintText: 'np. JanKowalski, finał, atak',
                ),
              ),
              const SizedBox(height: 24),
              
              // Kategoria wideo
              const Text('Kategoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Brak')),
                  ButtonSegment(value: 'Trening', label: Text('Trening')),
                  ButtonSegment(value: 'Mecz', label: Text('Mecz')),
                ],
                selected: {_videoCategory},
                onSelectionChanged: (Set<String?> newSelection) {
                  setState(() {
                    _videoCategory = newSelection.first;
                    _isDirty = true;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Drużyny i zawodnicy
              if (_videoCategory == 'Trening') ...[
                const Text('Zawodnicy / Drużyna (Trening)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildTeamSection(_teamA, 'Nazwa grupy / drużyny'),
              ] else if (_videoCategory == 'Mecz') ...[
                const Text('Drużyny (Mecz)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildTeamSection(_teamA, 'Drużyna A (np. Gospodarze)'),
                _buildTeamSection(_teamB, 'Drużyna B (np. Goście)'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
