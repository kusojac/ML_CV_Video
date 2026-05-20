class ActionModel {
  String id;
  String type;
  double startMs;
  double endMs;
  List<double>
  playerBox; // [x, y, w, h] or similar. Our backend gives [x_min, y_min, x_max, y_max].
  String playerId;
  double confidence;
  List<ActionModel> subActions;

  ActionModel({
    required this.id,
    required this.type,
    required this.startMs,
    required this.endMs,
    required this.playerBox,
    required this.playerId,
    required this.confidence,
    List<ActionModel>? subActions,
  }) : subActions = subActions ?? [];

  factory ActionModel.fromJson(Map<String, dynamic> json) {
    final subActionsJson = json['sub_actions'] as List?;
    final List<ActionModel> subs = subActionsJson != null
        ? subActionsJson
            .map((e) => ActionModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'start_ms': startMs,
      'end_ms': endMs,
      'player_box': playerBox,
      'player_id': playerId,
      'confidence': confidence,
      'sub_actions': subActions.map((e) => e.toJson()).toList(),
    };
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
