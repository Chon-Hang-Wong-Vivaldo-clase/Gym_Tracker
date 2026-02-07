import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'package:gym_tracker_app/widgets/auth_gate.dart';
import 'package:gym_tracker_app/providers/streak_provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/providers/auth_form_provider.dart';

import 'package:gym_tracker_app/widgets/widgets.dart'; // AppShell, AuthGate si lo metes ahí
import 'screens/screens.dart'; // LoginScreen, etc.

// IMPORTANTE: main async + initialize
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthFormProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider(), lazy: false),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GymTracker",
      home: const AuthGate(),
      routes: {
        'login': (_) => const LoginScreen(),
        'shell': (_) => const AppShell(),
        'routines': (_) => const RoutinesScreen(),
        'create_routine': (_) => const CreateRoutineScreen(),
        'complete_profile': (_) => const CompleteProfileScreen(),
      },
    );
  }
}
