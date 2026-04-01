import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/project_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const VolleyballApp());
}

class VolleyballApp extends StatelessWidget {
  const VolleyballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volleyball Action Analytics',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF03DAC6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
      ),
      home: const ProjectListScreen(),
    );
  }
}
