import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/action_model.dart';

/// Serwis odpowiedzialny za odczyt i zapis pliku _analysis.json
/// niezależnie od backendu FastAPI — operacje bezpośrednio na dysku.
class AnalysisFileService {
  // ─── Ścieżka domyślna (obok wideo) ───────────────────────────────────────

  static String defaultJsonPath(String videoPath) {
    final base = p.withoutExtension(videoPath);
    return '${base}_analysis.json';
  }

  static bool defaultJsonExists(String videoPath) {
    return File(defaultJsonPath(videoPath)).existsSync();
  }

  // ─── Zapis ────────────────────────────────────────────────────────────────

  /// Zapisuje listę akcji do domyślnego pliku JSON obok wideo.
  static Future<void> saveToDefault({
    required String videoPath,
    required List<ActionModel> actions,
    int? totalFrames,
    double? fps,
  }) async {
    final path = defaultJsonPath(videoPath);
    await _writeJson(path, actions, totalFrames: totalFrames, fps: fps);
  }

  /// Otwiera systemowe okno dialogowe "Zapisz jako" i zapisuje do wybranej lokalizacji.
  /// Zwraca ścieżkę do zapisanego pliku lub null, jeśli użytkownik anulował.
  static Future<String?> saveAs({
    required String videoPath,
    required List<ActionModel> actions,
    int? totalFrames,
    double? fps,
  }) async {
    final defaultName =
        '${p.basenameWithoutExtension(videoPath)}_analysis.json';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Zapisz wyniki analizy',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) return null;
    await _writeJson(savePath, actions, totalFrames: totalFrames, fps: fps);
    return savePath;
  }

  static Future<void> _writeJson(
    String path,
    List<ActionModel> actions, {
    int? totalFrames,
    double? fps,
  }) async {
    final Map<String, dynamic> payload = {
      if (totalFrames != null) 'total_frames': totalFrames,
      if (fps != null) 'fps': fps,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  // ─── Odczyt ───────────────────────────────────────────────────────────────

  /// Czyta domyślny plik JSON obok wideo.
  /// Zwraca null jeśli nie istnieje.
  static Future<AnalysisLoadResult?> loadFromDefault(String videoPath) async {
    final file = File(defaultJsonPath(videoPath));
    if (!file.existsSync()) return null;
    return _parseFile(file);
  }

  /// Otwiera systemowe okno dialogowe "Otwórz" i wczytuje wybrany plik JSON.
  /// Zwraca null jeśli użytkownik anulował lub wystąpił błąd.
  static Future<AnalysisLoadResult?> loadFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Wczytaj wyniki analizy (JSON)',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return null;
    return _parseFile(File(result.files.single.path!));
  }

  static Future<AnalysisLoadResult> _parseFile(File file) async {
    final contents = await file.readAsString();
    final json = jsonDecode(contents) as Map<String, dynamic>;
    final actionsList = (json['actions'] as List<dynamic>)
        .map((e) => ActionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnalysisLoadResult(
      actions: actionsList,
      totalFrames: (json['total_frames'] as num?)?.toInt(),
      fps: (json['fps'] as num?)?.toDouble(),
      sourcePath: file.path,
    );
  }
}

/// Wynik wczytania pliku JSON z analizą.
class AnalysisLoadResult {
  final List<ActionModel> actions;
  final int? totalFrames;
  final double? fps;
  final String sourcePath;

  const AnalysisLoadResult({
    required this.actions,
    required this.totalFrames,
    required this.fps,
    required this.sourcePath,
  });
}
