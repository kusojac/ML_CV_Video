import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
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

  void _removeProject(String path) {
    setState(() {
      _videoPaths.remove(path);
    });
    _saveProjects();
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
              child: Text(
                'No videos found.\nClick + to import a volleyball video.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _videoPaths.length,
              itemBuilder: (context, index) {
                final path = _videoPaths[index];
                final fileName = path.split(Platform.pathSeparator).last;
                return Card(
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.videocam, color: Colors.tealAccent, size: 40),
                    title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(path, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.purpleAccent),
                          onPressed: () => _removeProject(path),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54),
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
