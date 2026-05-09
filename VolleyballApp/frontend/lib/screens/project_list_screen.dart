import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analysis_file_service.dart';
import 'video_analysis_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<String> _videoPaths = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _videoPaths = prefs.getStringList('volleyball_projects') ?? [];
    });
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('volleyball_projects', _videoPaths);
  }

  Future<void> _importVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      if (!_videoPaths.contains(path)) {
        setState(() {
          _videoPaths.add(path);
        });
        await _saveProjects();
      }
    }
  }

  Future<void> _removeProject(String path) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text('Remove Project', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this project from the list?\n'
          'The video file will not be deleted from your disk.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _videoPaths.remove(path);
      });
      _saveProjects();
    }
  }

  Future<void> _confirmRemoveProject(String path) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text('Usuń projekt', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Czy na pewno chcesz usunąć ten projekt z listy?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj', style: TextStyle(color: Colors.white54)),
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
      _removeProject(path);
    }
  }

  void _openProject(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoAnalysisScreen(videoPath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _importVideo,
            tooltip: 'Import Video',
          )
        ],
      ),
      body: _videoPaths.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.white30),
                  SizedBox(height: 16),
                  Text(
                    'No videos found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click + to import a volleyball video.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _videoPaths.length,
              itemBuilder: (context, index) {
                final path = _videoPaths[index];
                final fileName = path.split(Platform.pathSeparator).last;
                final hasAnalysis = AnalysisFileService.defaultJsonExists(path);
                return Card(
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.videocam, color: Colors.tealAccent, size: 40),
                        if (hasAnalysis)
                          Positioned(
                            right: -4,
                            bottom: -2,
                            child: Tooltip(
                              message: 'Analiza dostępna',
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2A2A2A),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (hasAnalysis)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Tooltip(
                              message: 'Analiza zapisana',
                              child: Icon(Icons.analytics,
                                  color: Colors.greenAccent, size: 16),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(path,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.purpleAccent),
                          tooltip: 'Usuń projekt / Delete project',
                          onPressed: () => _confirmRemoveProject(path),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white54),
                      ],
                    ),
                    onTap: () => _openProject(path),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importVideo,
        label: const Text('Import Video'),
        icon: const Icon(Icons.video_call),
      ),
    );
  }
}
