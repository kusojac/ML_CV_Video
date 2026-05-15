import 'package:uuid/uuid.dart';
import 'team_metadata.dart';

enum ArtifactType {
  video,
  playlist,
  action,
}

class ArtifactModel {
  String id;
  ArtifactType type;
  String title;
  String description;
  List<String> tags;
  String filePath; // Zależnie od typu: plik wideo, plik JSON playlisty, lub referencja JSON akcji
  String? thumbnailPath;
  DateTime createdAt;
  
  // W przypadku typu "action" lub "playlist", wskazanie na plik wideo bazowy
  String? sourceVideoPath; 

  // Dodatkowe metadane dla wideo (mecz, trening)
  String? videoCategory; // np. 'Mecz', 'Trening'
  TeamMetadata? teamA;
  TeamMetadata? teamB;

  ArtifactModel({
    String? id,
    required this.type,
    required this.title,
    this.description = '',
    List<String>? tags,
    required this.filePath,
    this.thumbnailPath,
    DateTime? createdAt,
    this.sourceVideoPath,
    this.videoCategory,
    this.teamA,
    this.teamB,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  factory ArtifactModel.fromJson(Map<String, dynamic> json) {
    return ArtifactModel(
      id: json['id'],
      type: ArtifactType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ArtifactType.video,
      ),
      title: json['title'] ?? 'Bez nazwy',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      filePath: json['filePath'],
      thumbnailPath: json['thumbnailPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sourceVideoPath: json['sourceVideoPath'],
      videoCategory: json['videoCategory'],
      teamA: json['teamA'] != null ? TeamMetadata.fromJson(json['teamA']) : null,
      teamB: json['teamB'] != null ? TeamMetadata.fromJson(json['teamB']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'tags': tags,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'sourceVideoPath': sourceVideoPath,
      'videoCategory': videoCategory,
      'teamA': teamA?.toJson(),
      'teamB': teamB?.toJson(),
    };
  }
}
