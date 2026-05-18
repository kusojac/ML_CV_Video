import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/project_model.dart';
import '../models/artifact_model.dart';

class ProjectDataService {
  static final ProjectDataService _instance = ProjectDataService._internal();
  factory ProjectDataService() => _instance;
  ProjectDataService._internal();

  List<ProjectModel> _projects = [];
  List<ArtifactModel> _artifacts = [];

  List<ProjectModel> get projects => _projects;
  List<ArtifactModel> get artifacts => _artifacts;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _loadData();
    _initialized = true;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(directory.path, 'VolleyballApp'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir.path;
  }

  Future<File> get _projectsFile async {
    final path = await _localPath;
    return File(p.join(path, 'projects.json'));
  }

  Future<File> get _artifactsFile async {
    final path = await _localPath;
    return File(p.join(path, 'artifacts.json'));
  }

  Future<void> _loadData() async {
    try {
      final pFile = await _projectsFile;
      if (await pFile.exists()) {
        final String contents = await pFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        _projects = jsonList
            .map((json) => ProjectModel.fromJson(json))
            .toList();
      }

      final aFile = await _artifactsFile;
      if (await aFile.exists()) {
        final String contents = await aFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        _artifacts = jsonList
            .map((json) => ArtifactModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Błąd ładowania danych projektów: \$e');
    }
  }

  Future<void> _saveData() async {
    try {
      final pFile = await _projectsFile;
      final String pContents = jsonEncode(
        _projects.map((p) => p.toJson()).toList(),
      );
      await pFile.writeAsString(pContents);

      final aFile = await _artifactsFile;
      final String aContents = jsonEncode(
        _artifacts.map((a) => a.toJson()).toList(),
      );
      await aFile.writeAsString(aContents);
    } catch (e) {
      print('Błąd zapisu danych projektów: \$e');
    }
  }

  // --- Zarządzanie Projektami ---

  Future<void> createProject(ProjectModel project) async {
    _projects.add(project);
    await _saveData();
  }

  Future<void> updateProject(ProjectModel project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      await _saveData();
    }
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _saveData();
  }

  ProjectModel? getProjectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- Zarządzanie Artefaktami ---

  Future<void> createArtifact(ArtifactModel artifact) async {
    _artifacts.add(artifact);
    await _saveData();
  }

  Future<void> updateArtifact(ArtifactModel artifact) async {
    final index = _artifacts.indexWhere((a) => a.id == artifact.id);
    if (index != -1) {
      _artifacts[index] = artifact;
      await _saveData();
    }
  }

  Future<void> deleteArtifact(String id) async {
    _artifacts.removeWhere((a) => a.id == id);
    // Usuń też referencje z projektów
    for (var project in _projects) {
      if (project.artifactIds.contains(id)) {
        project.artifactIds.remove(id);
      }
    }
    await _saveData();
  }

  ArtifactModel? getArtifactById(String id) {
    try {
      return _artifacts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- Powiązania ---

  Future<void> linkArtifactToProject(
    String projectId,
    String artifactId,
  ) async {
    final project = getProjectById(projectId);
    if (project != null && !project.artifactIds.contains(artifactId)) {
      project.artifactIds.add(artifactId);
      await _saveData();
    }
  }

  Future<void> unlinkArtifactFromProject(
    String projectId,
    String artifactId,
  ) async {
    final project = getProjectById(projectId);
    if (project != null && project.artifactIds.contains(artifactId)) {
      project.artifactIds.remove(artifactId);
      await _saveData();
    }
  }
}
