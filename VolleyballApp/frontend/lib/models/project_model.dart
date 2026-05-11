import 'package:uuid/uuid.dart';

class ProjectModel {
  String id;
  String name;
  String description;
  List<String> tags;
  String? imagePath;
  DateTime createdAt;
  List<String> artifactIds;

  ProjectModel({
    String? id,
    required this.name,
    this.description = '',
    this.tags = const [],
    this.imagePath,
    DateTime? createdAt,
    this.artifactIds = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      imagePath: json['imagePath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      artifactIds: List<String>.from(json['artifactIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tags': tags,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'artifactIds': artifactIds,
    };
  }
}
