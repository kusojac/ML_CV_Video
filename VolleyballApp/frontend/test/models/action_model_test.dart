import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/action_model.dart';

void main() {
  group('ActionModel - Multiple Player Focuses', () {
    test('loads legacy JSON with only single player_box and player_id', () {
      final legacyJsonStr = '''
      {
        "id": "action_1",
        "type": "SERVE",
        "start_ms": 1200.0,
        "end_ms": 2200.0,
        "player_box": [10.0, 20.0, 30.0, 40.0],
        "player_id": "player_abc",
        "confidence": 0.98
      }
      ''';

      final action = ActionModel.fromJson(jsonDecode(legacyJsonStr));

      expect(action.playerFocuses.length, 1);
      expect(action.activeFocusId, 'focus_1');
      expect(action.playerFocuses.first.id, 'focus_1');
      expect(action.playerFocuses.first.name, 'Focus 1');
      expect(action.playerFocuses.first.playerId, 'player_abc');
      expect(action.playerFocuses.first.playerBox, [10.0, 20.0, 30.0, 40.0]);
    });

    test('serializes to JSON by syncing active focus to top-level fields', () {
      final action = ActionModel(
        id: 'action_1',
        type: 'SPIKE',
        startMs: 1000.0,
        endMs: 2000.0,
        playerBox: [0.0, 0.0, 0.0, 0.0],
        playerId: 'Unknown',
        confidence: 0.95,
        playerFocuses: [
          PlayerFocusModel(
            id: 'focus_attack',
            name: 'Atak',
            playerBox: [10.0, 10.0, 20.0, 20.0],
            playerId: 'player_attack_12',
          ),
          PlayerFocusModel(
            id: 'focus_defense',
            name: 'Obrona',
            playerBox: [50.0, 50.0, 60.0, 60.0],
            playerId: 'player_defense_4',
          ),
        ],
        activeFocusId: 'focus_defense',
      );

      final json = action.toJson();

      // Top-level box and ID must be synced to the active focus (focus_defense)
      expect(json['player_id'], 'player_defense_4');
      expect(json['player_box'], [50.0, 50.0, 60.0, 60.0]);
      expect(json['active_focus_id'], 'focus_defense');
      expect(json['player_focuses'].length, 2);
    });

    test('copyWith creates proper clones', () {
      final action = ActionModel(
        id: 'action_1',
        type: 'SPIKE',
        startMs: 1000.0,
        endMs: 2000.0,
        playerBox: [10.0, 10.0, 20.0, 20.0],
        playerId: 'player_1',
        confidence: 0.9,
      );

      final cloned = action.copyWith(
        activeFocusId: 'focus_new',
        playerFocuses: [
          PlayerFocusModel(
            id: 'focus_new',
            name: 'New Focus',
            playerBox: [30.0, 30.0, 40.0, 40.0],
            playerId: 'player_2',
          )
        ],
      );

      expect(cloned.activeFocusId, 'focus_new');
      expect(cloned.playerFocuses.length, 1);
      expect(cloned.playerFocuses.first.name, 'New Focus');
      // Original remains unaffected
      expect(action.activeFocusId, 'focus_1');
      expect(action.playerFocuses.length, 1);
      expect(action.playerFocuses.first.name, 'Focus 1');
    });
  });
}
