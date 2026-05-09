import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/screens/video_analysis_screen.dart';
import 'package:frontend/services/analytics_service.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  testWidgets('VideoAnalysisScreen error handling when analytics fails', (WidgetTester tester) async {
    // Configure screen size to prevent overflow errors from child widgets
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockService = MockAnalyticsService();
    // Simulate an exception being thrown when getting results
    when(() => mockService.getResults(any())).thenThrow(Exception('Simulated Failure'));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VideoAnalysisScreen(
          videoPath: 'test.mp4',
          analyticsService: mockService,
        ),
      ),
    ));

    // Pump to process the Future.microtask
    await tester.pump();

    // Verify the exception was caught and handled correctly
    // If not handled, pumpWidget/pump would fail with an uncaught exception
    expect(find.byType(VideoAnalysisScreen), findsOneWidget);
    expect(find.text('Analyze Video'), findsOneWidget);

    // Verify that the service was called once for the specific video path
    verify(() => mockService.getResults('test.mp4')).called(1);
  });
}
