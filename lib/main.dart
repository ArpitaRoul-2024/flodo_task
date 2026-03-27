import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/db/hive_service.dart';
import 'core/notification/notification_service.dart';
import 'features/tasks/screens/onboarding_screen.dart';
import 'features/tasks/screens/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ONLY load critical thing
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(ProviderScope(
    child: MyApp(seenOnboarding: seenOnboarding),
  ));

  // ✅ Run heavy stuff AFTER UI starts (non-blocking)
  _initServices();
}

// ✅ background init
Future<void> _initServices() async {
  await HiveService.init();
  await NotificationService.init();
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;

  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flodo Task',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D5BE3),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2D5BE3),
          secondary: Color(0xFFE8A838),
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF2D5BE3),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2D5BE3),
          secondary: Color(0xFFE8A838),
          surface: Color(0xFF1A1D2E),
        ),
      ),
      home: seenOnboarding
          ? const TaskListScreen()
          : const OnboardingScreen(),
    );
  }
}