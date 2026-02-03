import 'package:flutter/material.dart';
import 'package:gym_tracker_app/providers/streak_provider.dart';
import 'package:provider/provider.dart';

import 'package:gym_tracker_app/widgets/widgets.dart';
import 'screens/screens.dart';

void main() => runApp(AppState());

class AppState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      initialRoute: 'shell',
      routes: {
        'shell': (_) => const AppShell(),
        // si quieres rutas normales extra:
        'home': (_) => const HomeScreen(),
      },
    );
  }
}
