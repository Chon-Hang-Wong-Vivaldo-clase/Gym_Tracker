import 'package:flutter/material.dart';
import 'screens/screens.dart';
void main() {
  runApp(const MainApp());
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
