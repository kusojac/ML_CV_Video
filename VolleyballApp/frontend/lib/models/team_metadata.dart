class PlayerMetadata {
  String name;
  String number;
  String position;

  PlayerMetadata({
    required this.name,
    required this.number,
    required this.position,
  });

  factory PlayerMetadata.fromJson(Map<String, dynamic> json) {
    return PlayerMetadata(
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      position: json['position'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'number': number,
      'position': position,
    };
  }
}

class TeamMetadata {
  String name;
  List<PlayerMetadata> players;

  TeamMetadata({
    required this.name,
    List<PlayerMetadata>? players,
  }) : players = players ?? [];

  factory TeamMetadata.fromJson(Map<String, dynamic> json) {
    var playersJson = json['players'] as List? ?? [];
    return TeamMetadata(
      name: json['name'] ?? '',
      players: playersJson.map((p) => PlayerMetadata.fromJson(p)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'players': players.map((p) => p.toJson()).toList(),
    };
  }
}
