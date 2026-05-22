class PlayerFocusModel {
  final String id;
  final String name;
  final List<double> playerBox; // [x_min, y_min, x_max, y_max]
  final String playerId;

  PlayerFocusModel({
    required this.id,
    required this.name,
    required this.playerBox,
    required this.playerId,
  });

  factory PlayerFocusModel.fromJson(Map<String, dynamic> json) {
    return PlayerFocusModel(
      id: json['id'] as String,
      name: json['name'] as String,
      playerBox: (json['player_box'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      playerId: json['player_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'player_box': playerBox,
      'player_id': playerId,
    };
  }

  PlayerFocusModel copyWith({
    String? id,
    String? name,
    List<double>? playerBox,
    String? playerId,
  }) {
    return PlayerFocusModel(
      id: id ?? this.id,
      name: name ?? this.name,
      playerBox: playerBox ?? List<double>.from(this.playerBox),
      playerId: playerId ?? this.playerId,
    );
  }
}

class ActionModel {
  String id;
  String type;
  double startMs;
  double endMs;
  List<double> playerBox; // [x, y, w, h] or similar. Our backend gives [x_min, y_min, x_max, y_max].
  String playerId;
  double confidence;
  List<ActionModel> subActions;

  List<PlayerFocusModel> playerFocuses;
  String? activeFocusId;

  ActionModel({
    required this.id,
    required this.type,
    required this.startMs,
    required this.endMs,
    required this.playerBox,
    required this.playerId,
    required this.confidence,
    List<ActionModel>? subActions,
    List<PlayerFocusModel>? playerFocuses,
    this.activeFocusId,
  })  : subActions = subActions ?? [],
        playerFocuses = playerFocuses ?? [] {
    // If playerFocuses is empty, generate a default one using playerBox and playerId
    if (this.playerFocuses.isEmpty) {
      final defaultFocus = PlayerFocusModel(
        id: 'focus_1',
        name: 'Focus 1',
        playerBox: List<double>.from(playerBox),
        playerId: playerId,
      );
      this.playerFocuses.add(defaultFocus);
      activeFocusId ??= defaultFocus.id;
    } else {
      // Ensure activeFocusId points to a valid focus or default to the first one
      if (activeFocusId == null || !this.playerFocuses.any((f) => f.id == activeFocusId)) {
        activeFocusId = this.playerFocuses.first.id;
      }
    }
  }

  factory ActionModel.fromJson(Map<String, dynamic> json) {
    final subActionsJson = json['sub_actions'] as List?;
    final List<ActionModel> subs = subActionsJson != null
        ? subActionsJson
            .map((e) => ActionModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    final playerFocusesJson = json['player_focuses'] as List?;
    final List<PlayerFocusModel> focuses = playerFocusesJson != null
        ? playerFocusesJson
            .map((e) => PlayerFocusModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    final activeFocusId = json['active_focus_id'] as String?;

    return ActionModel(
      id: json['id'],
      type: json['type'],
      startMs: (json['start_ms'] as num).toDouble(),
      endMs: (json['end_ms'] as num).toDouble(),
      playerBox: (json['player_box'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      playerId: json['player_id'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      subActions: subs,
      playerFocuses: focuses,
      activeFocusId: activeFocusId,
    );
  }

  Map<String, dynamic> toJson() {
    // Sync top-level playerBox and playerId with the active focus if it exists
    final activeFocus = playerFocuses.firstWhere(
      (f) => f.id == activeFocusId,
      orElse: () => playerFocuses.isNotEmpty ? playerFocuses.first : PlayerFocusModel(id: 'dummy', name: 'Dummy', playerBox: playerBox, playerId: playerId),
    );
    
    playerBox = List<double>.from(activeFocus.playerBox);
    playerId = activeFocus.playerId;

    return {
      'id': id,
      'type': type,
      'start_ms': startMs,
      'end_ms': endMs,
      'player_box': playerBox,
      'player_id': playerId,
      'confidence': confidence,
      'sub_actions': subActions.map((e) => e.toJson()).toList(),
      'player_focuses': playerFocuses.map((e) => e.toJson()).toList(),
      'active_focus_id': activeFocusId,
    };
  }

  ActionModel copyWith({
    String? id,
    String? type,
    double? startMs,
    double? endMs,
    List<double>? playerBox,
    String? playerId,
    double? confidence,
    List<ActionModel>? subActions,
    List<PlayerFocusModel>? playerFocuses,
    String? activeFocusId,
  }) {
    return ActionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      playerBox: playerBox ?? List<double>.from(this.playerBox),
      playerId: playerId ?? this.playerId,
      confidence: confidence ?? this.confidence,
      subActions: subActions ?? this.subActions.map((e) => e.copyWith()).toList(),
      playerFocuses: playerFocuses ?? this.playerFocuses.map((e) => e.copyWith()).toList(),
      activeFocusId: activeFocusId ?? this.activeFocusId,
    );
  }
}

const List<String> kVolleyballActions = [
  'POINT',
  'RALLY',
  'SERVE',
  'JUMP SERVE',
  'FLOAT SERVE',
  'RECEIVE',
  'BUMP',
  'SET',
  'ATTACK',
  'LEFT SPIKE',
  'RIGHT SPIKE',
  'MIDDLE SPIKE',
  'BLOCK',
  'DIG',
  'FREEBALL',
];
