import 'package:flutter/material.dart';
import 'package:gym_tracker_app/providers/streak_provider.dart';
import 'package:gym_tracker_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'screens/screens.dart';
void main() => runApp(AppState());

class AppState extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => StreakProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider())
      ],
      child: MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  
  const MainApp({super.key});
  //isUserLogged = "Añadir instancia de FireBaseAuth.currentUser"
  //if initialRoute : "home" ? "login"

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GymTracker",
      //theme: ThemeData.dark, //add function to change theme in settings
      initialRoute: 'home',
      routes: {
        'home': (_) => const HomeScreen(),
      },
    );
  }
}
