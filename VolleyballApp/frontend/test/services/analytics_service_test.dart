import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/analytics_service.dart';

void main() {
  group('AnalyticsService - getResults', () {
    test('returns list of ActionModel on API success (200 OK)', () async {
      // 1. Set up MockClient
      final mockClient = MockClient((request) async {
        if (request.url.path == '/results') {
          return http.Response(
            jsonEncode({
              'actions': [
                {
                  'id': '1',
                  'type': 'SERVE',
                  'start_ms': 1000.0,
                  'end_ms': 2000.0,
                  'player_box': [10.0, 20.0, 30.0, 40.0],
                  'player_id': 'Player 1',
                  'confidence': 0.95
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // 2. Initialize Service
      final service = AnalyticsService(client: mockClient);

      // 3. Call Method
      final result = await service.getResults('test_video.mp4');

      // 4. Assertions
      expect(result.length, 1);
      expect(result[0].id, '1');
      expect(result[0].type, 'SERVE');
      expect(result[0].startMs, 1000.0);
    });

    test('falls back to local JSON file on API failure (e.g. 500 Error)', () async {
      // 1. Set up MockClient to fail
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = AnalyticsService(client: mockClient);
      final videoPath = 'test_video_fallback.mp4';
      final expectedFallbackPath = 'test_video_fallback_analysis.json';

      // 2. Create the fallback file
      final file = File(expectedFallbackPath);
      await file.writeAsString(jsonEncode({
        'actions': [
          {
            'id': '2',
            'type': 'SPIKE',
            'start_ms': 3000.0,
            'end_ms': 4000.0,
            'player_box': [50.0, 60.0, 70.0, 80.0],
            'player_id': 'Player 2',
            'confidence': 0.85
          }
        ]
      }));

      try {
        // 3. Call Method
        final result = await service.getResults(videoPath);

        // 4. Assertions
        expect(result.length, 1);
        expect(result[0].id, '2');
        expect(result[0].type, 'SPIKE');
      } finally {
        // 5. Cleanup
        if (await file.exists()) {
          await file.delete();
        }
      }
    });

    test('throws Exception when API fails and local file is missing', () async {
      // 1. Set up MockClient to fail
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = AnalyticsService(client: mockClient);
      final videoPath = 'test_video_missing.mp4';
      final expectedFallbackPath = 'test_video_missing_analysis.json';

      // 2. Ensure fallback file does NOT exist
      final file = File(expectedFallbackPath);
      if (await file.exists()) {
        await file.delete();
      }

      // 3. Call Method and verify exception
      expect(
        () => service.getResults(videoPath),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to get results')),
        ),
      );
    });
  });
}
