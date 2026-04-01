import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/action_model.dart';
import 'dart:io';

class AnalyticsService {
  static const String baseUrl = 'http://127.0.0.1:8001';

  Future<String> startAnalysis(String videoPath) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'video_path': videoPath}),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'completed') {
        return 'completed'; // Already done
      }
      return jsonResponse['job_id'];
    } else {
      throw Exception('Failed to start analysis');
    }
  }

  Future<Map<String, dynamic>> checkJobStatus(String jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/job/$jobId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return {
        'status': jsonResponse['status'],
        'progress': jsonResponse['progress'] ?? 0.0,
        'eta_seconds': jsonResponse['eta_seconds'],
      };
    }
    throw Exception('Failed to check status');
  }

  Future<List<ActionModel>> getResults(String videoPath) async {
    // We can just try reading the local json file directly instead of HTTP if it's the same machine
    // But let's use the API for correctness
    final response = await http
        .get(Uri.parse('$baseUrl/results?video_path=${Uri.encodeComponent(videoPath)}'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final actions = jsonResponse['actions'] as List;
      return actions.map((v) => ActionModel.fromJson(v)).toList();
    }
    // Fallback: try reading the JSON file locally if API is down
    final path = '${videoPath.substring(0, videoPath.lastIndexOf('.'))}_analysis.json';
    if (File(path).existsSync()) {
      final contents = await File(path).readAsString();
      final jsonResponse = jsonDecode(contents);
      final actions = jsonResponse['actions'] as List;
      return actions.map((v) => ActionModel.fromJson(v)).toList();
    }
    throw Exception('Failed to get results');
  }

  Future<void> updateAction(String videoPath, ActionModel action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_action'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'video_path': videoPath,
        'action_id': action.id,
        'new_type': action.type,
        'new_start_ms': action.startMs,
        'new_end_ms': action.endMs,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update action');
    }
  }
}
