import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/home_screen.dart';
import 'services/project_data_service.dart';
import 'theme/kinetic_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await ProjectDataService().init();
  runApp(const VolleyballApp());
}

class VolleyballApp extends StatelessWidget {
  const VolleyballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volleyball Action Analytics',
      theme: KineticTheme.themeData,
      home: const HomeScreen(),
    );
  }
}
