import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'package:gym_tracker_app/widgets/auth_gate.dart';
import 'package:gym_tracker_app/providers/streak_provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/providers/auth_form_provider.dart';
import 'package:gym_tracker_app/providers/theme_provider.dart';

import 'package:gym_tracker_app/widgets/widgets.dart';
import 'screens/screens.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      debugPrint('FlutterError: ${details.exception}');
      debugPrint(details.stack?.toString() ?? '');
    };

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      runApp(const AppState());
    } catch (e, stack) {
      debugPrint('Firebase init error: $e');
      debugPrint(stack.toString());
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $e', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ));
    }
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint(stack.toString());
  });
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
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    const lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2B2E34),
      onPrimary: Colors.white,
      secondary: Color(0xFF6C7075),
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: Color(0xFFF2F3F5),
      onSurface: Color(0xFF111111),
      primaryContainer: Color(0xFFE0E3E7),
      onPrimaryContainer: Color(0xFF111111),
      secondaryContainer: Color(0xFFE4E6EA),
      onSecondaryContainer: Color(0xFF111111),
      tertiary: Color(0xFF757575),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE2E2E2),
      onTertiaryContainer: Color(0xFF111111),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      outline: Color(0xFFBDBDBD),
      outlineVariant: Color(0xFFE0E0E0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF1F1F1F),
      onInverseSurface: Color(0xFFF5F5F5),
      inversePrimary: Color(0xFFC7C9CC),
      surfaceTint: Color(0xFF2B2E34),
    );
    const darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFE0E0E0),
      onPrimary: Color(0xFF111111),
      secondary: Color(0xFFB0B0B0),
      onSecondary: Color(0xFF111111),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: Color(0xFF121212),
      onSurface: Color(0xFFECECEC),
      primaryContainer: Color(0xFF2A2D31),
      onPrimaryContainer: Color(0xFFECECEC),
      secondaryContainer: Color(0xFF2E2F33),
      onSecondaryContainer: Color(0xFFECECEC),
      tertiary: Color(0xFF9E9E9E),
      onTertiary: Color(0xFF111111),
      tertiaryContainer: Color(0xFF2B2B2B),
      onTertiaryContainer: Color(0xFFECECEC),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      outline: Color(0xFF8C8C8C),
      outlineVariant: Color(0xFF4A4A4A),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFECECEC),
      onInverseSurface: Color(0xFF1A1A1A),
      inversePrimary: Color(0xFF3F4348),
      surfaceTint: Color(0xFFE0E0E0),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GymTracker",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111111),
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2B2E34),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Color(0xFFECECEC),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFFE0E0E0),
          contentTextStyle: TextStyle(color: Color(0xFF111111)),
        ),
      ),
      themeMode: themeNotifier.themeMode,
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
