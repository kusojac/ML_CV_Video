import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/action_model.dart';
import 'package:frontend/screens/video_analysis_screen.dart';
import 'package:frontend/services/analytics_service.dart';
import 'package:media_kit/media_kit.dart';

class MockAnalyticsService implements AnalyticsService {
  @override
  Future<List<ActionModel>> getResults(String videoPath) async {
    throw Exception('Test Error');
  }

  @override
  Future<String> startAnalysis(String videoPath) async {
    return 'completed';
  }

  @override
  Future<Map<String, dynamic>> checkJobStatus(String jobId) async {
    return {'status': 'completed'};
  }

  @override
  Future<void> updateAction(String videoPath, ActionModel action) async {
    return;
  }
}

void main() {
  setUpAll(() {
    MediaKit.ensureInitialized();
  });

  testWidgets('Renders screen and handles getResults exception gracefully', (WidgetTester tester) async {
    // Override flutter test error handling to ignore overflow errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is FlutterError && (details.exception as FlutterError).message.contains('overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    final mockService = MockAnalyticsService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoAnalysisScreen(
            videoPath: 'dummy_path.mp4',
            analyticsService: mockService,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the UI is still rendered, the exception is caught, and no error message is shown.
    expect(find.byType(VideoAnalysisScreen), findsOneWidget);
    expect(find.textContaining('Test Error'), findsNothing);
  });
}
