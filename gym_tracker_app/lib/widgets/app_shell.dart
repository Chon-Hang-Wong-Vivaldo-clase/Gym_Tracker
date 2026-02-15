import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import 'package:gym_tracker_app/screens/screens.dart';

/// Altura del footer: barra fina y discreta.
const double _kNavBarHeight = 56.0;

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

  List<PersistentBottomNavBarItem> _items(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? theme.colorScheme.primary : const Color(0xFF2B2E34);
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.5);
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined, size: 24),
        title: "Inicio",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline, size: 24),
        title: "Perfil",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.people_outline, size: 24),
        title: "Social",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _screens(),
      items: _items(context),
      navBarStyle: NavBarStyle.style1,
      navBarHeight: _kNavBarHeight,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      confineToSafeArea: true,
      hideNavigationBarWhenKeyboardAppears: true,
      handleAndroidBackButtonPress: true,
      stateManagement: true,
      animationSettings: NavBarAnimationSettings(
        navBarItemAnimation: const ItemAnimationSettings(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
        ),
        screenTransitionAnimation: const ScreenTransitionAnimationSettings(
          animateTabTransition: true,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          screenTransitionAnimationType: ScreenTransitionAnimationType.slide,
        ),
      ),
    );
  }
}
