class ActionModel {
  String id;
  String type;
  double startMs;
  double endMs;
  List<double> playerBox; // [x, y, w, h] or similar. Our backend gives [x_min, y_min, x_max, y_max].
  String playerId;
  double confidence;

  ActionModel({
    required this.id,
    required this.type,
    required this.startMs,
    required this.endMs,
    required this.playerBox,
    required this.playerId,
    required this.confidence,
  });

  factory ActionModel.fromJson(Map<String, dynamic> json) {
    return ActionModel(
      id: json['id'],
      type: json['type'],
      startMs: (json['start_ms'] as num).toDouble(),
      endMs: (json['end_ms'] as num).toDouble(),
      playerBox: (json['player_box'] as List).map((e) => (e as num).toDouble()).toList(),
      playerId: json['player_id'] ?? 'Unknown',
      confidence: (json['confidence'] as num).toDouble(),
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
    };
  }
}

const List<String> kVolleyballActions = [
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
