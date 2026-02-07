import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import 'package:gym_tracker_app/screens/screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _screens() => const [
    HomeScreen(),
    ProfileScreen(),
    SocialScreen(),
  ];

  List<PersistentBottomNavBarItem> _items() => [
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.home),
      title: "Inicio",
      activeColorPrimary: const Color(0xFF2B2E34),
      inactiveColorPrimary: Colors.grey,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.person),
      title: "Perfil",
      activeColorPrimary: const Color(0xFF2B2E34),
      inactiveColorPrimary: Colors.grey,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.people),
      title: "Social",
      activeColorPrimary: const Color(0xFF2B2E34),
      inactiveColorPrimary: Colors.grey,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _screens(),
      items: _items(),
      navBarStyle: NavBarStyle.style14,
      backgroundColor: Colors.white,
      confineToSafeArea: true,
      hideNavigationBarWhenKeyboardAppears: true,
      handleAndroidBackButtonPress: true,
      stateManagement: false,
    );
  }
}
