import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/action_model.dart';
import 'package:frontend/services/analysis_file_service.dart';

void main() {
  group('AnalysisFileService', () {
    final String testVideoPath = 'test_video.mp4';
    final String expectedJsonPath = 'test_video_analysis.json';
    final String expectedPlaylistPath = 'test_video_playlist.json';

    final List<ActionModel> testActions = [
      ActionModel(
        id: '1',
        type: 'SERVE',
        startMs: 1000.0,
        endMs: 2000.0,
        playerBox: [10.0, 20.0, 30.0, 40.0],
        playerId: 'Player 1',
        confidence: 0.95,
      ),
      ActionModel(
        id: '2',
        type: 'SPIKE',
        startMs: 3000.0,
        endMs: 4000.0,
        playerBox: [50.0, 60.0, 70.0, 80.0],
        playerId: 'Player 2',
        confidence: 0.85,
      ),
    ];

    setUp(() {
      // Ensure test files do not exist before each test
      if (File(expectedJsonPath).existsSync()) {
        File(expectedJsonPath).deleteSync();
      }
      if (File(expectedPlaylistPath).existsSync()) {
        File(expectedPlaylistPath).deleteSync();
      }
    });

    tearDown(() {
      // Clean up test files after each test
      if (File(expectedJsonPath).existsSync()) {
        File(expectedJsonPath).deleteSync();
      }
      if (File(expectedPlaylistPath).existsSync()) {
        File(expectedPlaylistPath).deleteSync();
      }
    });

    test('defaultJsonPath returns correct path', () {
      final path = AnalysisFileService.defaultJsonPath(testVideoPath);
      expect(path, expectedJsonPath);
    });

    test('defaultPlaylistJsonPath returns correct path', () {
      final path = AnalysisFileService.defaultPlaylistJsonPath(testVideoPath);
      expect(path, expectedPlaylistPath);
    });

    test('defaultJsonExists returns false when file does not exist', () {
      expect(AnalysisFileService.defaultJsonExists(testVideoPath), isFalse);
    });

    test('saveToDefault creates JSON file with correct data', () async {
      await AnalysisFileService.saveToDefault(
        videoPath: testVideoPath,
        actions: testActions,
        totalFrames: 100,
        fps: 30.0,
      );

      expect(AnalysisFileService.defaultJsonExists(testVideoPath), isTrue);

      final result = await AnalysisFileService.loadFromDefault(testVideoPath);
      expect(result, isNotNull);
      expect(result!.actions.length, 2);
      expect(result.actions[0].id, '1');
      expect(result.actions[1].type, 'SPIKE');
      expect(result.totalFrames, 100);
      expect(result.fps, 30.0);
      expect(result.sourcePath, expectedJsonPath);
    });

    test('loadFromDefault returns null if file does not exist', () async {
      final result = await AnalysisFileService.loadFromDefault(testVideoPath);
      expect(result, isNull);
    });

    test('savePlaylistToDefault creates JSON file correctly', () async {
      await AnalysisFileService.savePlaylistToDefault(
        videoPath: testVideoPath,
        playlist: testActions,
      );

      final file = File(expectedPlaylistPath);
      expect(file.existsSync(), isTrue);

      final contents = await file.readAsString();
      expect(contents, contains('SERVE'));
      expect(contents, contains('SPIKE'));
    });
  });
}
