import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/providers/theme_provider.dart';
import 'package:gym_tracker_app/screens/training_history_screen.dart';
import 'package:gym_tracker_app/widgets/auth_gate.dart';

class AppEndDrawer extends StatefulWidget {
  const AppEndDrawer({super.key});

  @override
  State<AppEndDrawer> createState() => _AppEndDrawerState();
}

class _AppEndDrawerState extends State<AppEndDrawer> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final user = auth.user;
    final uid = user?.uid;
    final profileRef = uid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$uid/profile');
    final settingsRef = uid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$uid/settings');

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(height: 8),
              _ProfileHeader(userEmail: user?.email, profileRef: profileRef),
              _SettingsPanel(
                label: "Activo",
                activeTrackColor: const Color(0xFF4CAF50),
                inactiveTrackColor: const Color(0xFFBDBDBD),
                settingsRef: settingsRef,
                fieldKey: "active",
                fallback: false,
              ),
              const SizedBox(height: 6),
              _LocalSwitch(
                label: "Tema Oscuro",
                activeTrackColor: const Color(0xFF4CAF50),
                inactiveTrackColor: const Color(0xFFBDBDBD),
                value: themeNotifier.isDarkMode,
                onChanged: (next) {
                  themeNotifier.setDarkMode(next);
                },
              ),
              const SizedBox(height: 24),
              _DrawerButton(
                label: "Crear una nueva rutina",
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('create_routine');
                },
              ),
              const SizedBox(height: 12),
              _DrawerButton(
                label: "Mis rutinas",
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('routines');
                },
              ),
              const SizedBox(height: 12),
              _DrawerButton(
                label: "Historial de entrenos",
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TrainingHistoryScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
              _LogoutButton(
                onPressed: () async {
                  await context.read<AppAuthProvider>().signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).maybePop();
                  Navigator.of(context, rootNavigator: true)
                      .pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (_) => false,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.label,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.settingsRef,
    required this.fieldKey,
    required this.fallback,
  });

  final String label;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final DatabaseReference? settingsRef;
  final String fieldKey;
  final bool fallback;

  @override
  Widget build(BuildContext context) {
    if (settingsRef == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PresenceStatusView(isActive: false),
          const SizedBox(height: 18),
          _SwitchRow(
            label: label,
            value: fallback,
            activeTrackColor: activeTrackColor,
            inactiveTrackColor: inactiveTrackColor,
            onChanged: null,
          ),
        ],
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: settingsRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final isActive = (data[fieldKey] ?? fallback) == true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PresenceStatusView(isActive: isActive),
            const SizedBox(height: 18),
            _SwitchRow(
              label: label,
              value: isActive,
              activeTrackColor: activeTrackColor,
              inactiveTrackColor: inactiveTrackColor,
              onChanged: (next) async {
                await settingsRef!.child(fieldKey).set(next);
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userEmail, required this.profileRef});

  final String? userEmail;
  final DatabaseReference? profileRef;

  @override
  Widget build(BuildContext context) {
    if (profileRef == null) {
      return _ProfileContent(
        name: "Invitado",
        email: userEmail ?? "Sin email",
        photoUrl: null,
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: profileRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final name = (data["name"] ?? "").toString();
        final surname = (data["surname"] ?? "").toString();
        final displayName = [
          name,
          surname,
        ].where((value) => value.trim().isNotEmpty).join(' ').trim();
        final email = (data["email"] ?? userEmail ?? "Sin email").toString();
        final photoUrl = data["photoUrl"]?.toString();

        return _ProfileContent(
          name: displayName.isEmpty ? "Usuario" : displayName,
          email: email,
          photoUrl: photoUrl,
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE0E0E0),
          backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
          child: photoUrl == null
              ? const Icon(Icons.person, color: Colors.black54)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresenceStatusView extends StatelessWidget {
  const _PresenceStatusView({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2E7D32) : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? "Conectado" : "Desconectado",
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LocalSwitch extends StatelessWidget {
  const _LocalSwitch({
    required this.label,
    required this.value,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SwitchRow(
      label: label,
      value: value,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      onChanged: onChanged,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: activeTrackColor,
          inactiveTrackColor: inactiveTrackColor,
          thumbColor: const MaterialStatePropertyAll<Color>(Colors.white),
          trackOutlineColor: const MaterialStatePropertyAll<Color>(
            Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C7075),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B2E34),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.logout),
        label: const Text("Cerrar Sesión"),
      ),
    );
  }
}
